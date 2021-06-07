require 'fileutils'
require_relative './util'
require 'json'
require 'pathname'
require 'dispel'
require 'versionomy'

VERSION_REGEX = /(.version\s*=\s*["'])(\d+.\d+.\d+)(["'])/i

class PBPodVersionPicker
    attr_accessor:position
    attr_accessor:playlist
    attr_accessor:cur
    attr_accessor:confirm

    def initialize(ver)
        @cur = Versionomy.parse(ver)

        @playlist = Array.new
        @playlist.push("#{@cur.major}.#{@cur.minor}.#{@cur.tiny+1}")
        @playlist.push("#{@cur.major}.#{@cur.minor+1}.#{0}")
        @playlist.push("#{@cur.major+1}.#{0}.#{0}")
        @position = 0
    end

    def newVer()
        return @playlist[@position]
    end
  
    def show_playlist
        vt = ["主要", "次要", "修正"]
        @playlist.each_with_index.map do |song, index|
            position == index ? "※ #{vt[index]} #{song}" : "  #{vt[index]} #{song} "
        end
    end
end

class PBPodUtility
    def show_ui playlist_obj
        ["\n", playlist_obj.show_playlist, "\n当前版本: #{playlist_obj.cur.to_s} "].join("\n")
    end

    def initialize(options)
        conf = "#{File.dirname(__FILE__)}/../pod.config.json"
        if options[:repo]
            setRepo(conf, options[:name])
        elsif options[:pod]
            if File::exist?(conf)
                config = JSON.parse(File.read(conf))
                publish(config['repo'])                
            else
                puts PBUtil::error("请先设置repo名称")
            end
        end
    end

    def setRepo(conf, repo)
        puts conf
        config = Hash.new
        if repo.nil?
            config = JSON.parse(File.read(conf))
            puts PBUtil.warn("请输入repo名称，当前为#{config['repo']}")
            return
        end
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
            curver = nil
            file_content.scan(VERSION_REGEX) do|match|
                curver = match[1]
            end

            if curver.nil? || curver.scan(/(\d+.\d+.\d+)/).length ==0 
                puts PBUtil.error("[!] 未找到符合的版本号 #{curver}")
                return
            end

            pd = PBPodVersionPicker.new(curver)

            Dispel::Screen.open do |screen|
                screen.draw show_ui(pd)
              
                Dispel::Keyboard.output do |key|
                  case key
                  when :up then pd.position = [pd.position-1, 0].max
                  when :down then pd.position = [pd.position+1, pd.playlist.length-1].min
                  when :enter then pd.confirm = true
                  when "q" then break
                  end
                  if pd.confirm 
                    break
                  end
                  screen.draw show_ui(pd)
                end
            end

            if !pd.confirm
                puts "取消发布"
                return
            end
            new_version = pd.newVer()
            puts PBUtil.warn("确认发布版本#{new_version.to_s}到`#{repo}`? [yN]\n")
            if STDIN.gets.chomp.downcase.eql?('y')
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
                git reset --hard
                git pull
                rm -rf #{new_version}
                mkdir #{new_version}
                cp -r #{Dir.pwd}/#{podspec} #{ENV['HOME']}/.cocoapods/repos/#{repo}/#{name}/#{new_version}
                git add .
                git commit -m '[Add] #{name} #{new_version}'
                git push
                `
                puts PBUtil.debug("#{name} #{new_version} 发布成功")
            end
        end
    end

    def versionSelect()
        
    end

    def showUsage()
        puts "用法: command #{PBUtil::warn('[选项]')}
    
    命令:
        repo    [name]      设置私有仓库地址
        publish             发布新版本
        "
    end

end