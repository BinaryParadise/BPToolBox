require 'fileutils'
require_relative './util'
require 'json'
require 'pathname'

VERSION_REGEX = /(.version\s*=\s*")(\d+.\d+.\d+)(")/i

class PBPodUtility
    def initialize(param)
        conf = "#{File.dirname(__FILE__)}/../pod.config.json"
        params = param.params
        if params.length == 0
            showUsage()
        else
            action = params[0]
            if action.eql?('repo')
                setRepo(conf, params[1])
            elsif action.eql?('publish')
                if File::exist?(conf)
                    config = JSON.parse(File.read(conf))
                    publish(config['repo'])                
                else
                    puts PBUtil::error("请先设置repo名称")
                end
            end
        end
    end

    def setRepo(conf, repo)
        puts conf
        config = Hash.new
        config['repo'] = repo
        json_file = File.new(conf, 'w+')
        json_file.write(JSON.pretty_generate(config))
        puts PBUtil.info("当前repo变更为#{repo}")
    end

    # 发布版本
    def publish(repo)
        if repo.nil?
            puts PBUtil::error("请先设置repo")
            return
        end
        `git pull --verbose
        `
        podspec = Dir::entries(Dir.pwd).filter{|item|(
            File.extname(item).eql?(".podspec")
        )}.first
        if podspec.nil?
            PBUtil.error("[!] Unable to find a podspec in the working directory")
        else
            file_content = File.read(podspec)
            file_content.scan(VERSION_REGEX) do|match|
                puts PBUtil.warn("当前版本#{match[1]}")
            end

            print "请输入要发布的版本: \n"
            new_version = STDIN.gets.chomp
            if new_version.nil? || new_version.scan(/(\d+.\d+.\d+)/).length ==0 
                puts PBUtil.error("版本号不符合规范，请重新输入!")
                return
            end
            print "确认发布版本#{new_version}? [y:是 n：否]\n"
            if STDIN.gets.chomp.eql?('y')
                name = podspec.gsub(/.podspec/, '')
                puts PBUtil.info("开始发布#{name}新版本[#{new_version}]")
                File.open(podspec, "r+") do |aFile|
                    aFile.syswrite(file_content.gsub(VERSION_REGEX, "\\1#{new_version}\\3"))
                end
                
                if !File.exist?("#{ENV['HOME']}/.cocoapods/repos/#{repo}/#{name}")
                    `mkdir #{ENV['HOME']}/.cocoapods/repos/#{repo}/#{name}`
                end

                # 修改版本号，创建指定版本tag
                `
                git add .
                git commit -m '[toolbox] release #{new_version}'
                git push
                git tag -a -m  -f #{new_version}
                git push -v origin refs/tags/#{new_version}
                `
                
                # spec仓库增加指定版本podspc
                `
                cd #{ENV['HOME']}/.cocoapods/repos/#{repo}/#{name}
                git pull
                rm -rf #{new_version}
                mkdir #{new_version}
                cp -r #{Dir.pwd}/#{podspec} #{ENV['HOME']}/.cocoapods/repos/#{repo}/#{name}/#{new_version}
                git add .
                git commit -m '[Add] #{name} #{new_version}'
                # git push
                `
                puts PBUtil.debug("#{name} #{new_version} 发布成功")
            end
        end
    end

    def showUsage()
        puts "用法: command #{PBUtil::warn('[选项]')}
    
    命令:
        repo    [name]      设置私有仓库地址
        publish             发布新版本
        "
    end

end