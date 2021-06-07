require 'fileutils'
require_relative './util'
require_relative './param'
require 'json'
require 'xcodeproj'
require 'pry'

# author: Rake Yang
# 图片工具
# 2021-3-17
class PBImage
  def initialize(options)
    param = PBParam.new(options)
    if options[:arrange]
      arrange(param)
    else
      imageReset(param)
    end
  end

  # 图片整理去重
  def arrange(param)    
    if param.imagePaths.nil?
      puts PBUtil::error("未配置图片路径")
    end
    images = []
    refs = {}
    puts "正在收集信息..."
    sleep 1
    param.imagePaths.each{ |item|
    (
      collectImage(item, images)
    )}
    param.sourcePaths.each{|item|
    (
      if File::exist?(item)
        extractImageRef(item, refs)        
      else
        puts PBUtil::error("文件夹不存在 #{item}")
      end
    )}
    
    count = 0
    d = 0
    completed = 0
    repeats = {}
    confirm = []
    images.each{ |item|
    (
      completed = completed + 1
      print "正在处理#{completed}/#{images.count}...\r"
      STDOUT.flush
      checkSha256(item["path"], repeats)
      next if refs.key?(item["name"])
      count = count + 1
      name = item["name"]
      if name.scan(/(\d+)/).count > 0
        confirm.push(item)
      else        
        `rm -rf #{item["path"]}`
        puts "删除图片 #{item["path"]}"
        d = d + 1
      end
    )}

    puts PBUtil::warn("以下图片可能存在动态拼接逻辑，请手动处理!")
    
    confirm.each{|item|(
      puts PBUtil::info("#{item["name"]} => #{item["path"]}")
    )}

    puts PBUtil::warn("重复图片")

    repeats.each{|key,value|(
      next if value.count <= 1
      puts value
    )}

    puts ""
    puts PBUtil::debug("处理完成，删除未引用图片 #{d}/#{count}, 待确认#{confirm.count}")

  end  
  
  # 检查重复图片
  def checkSha256(sourcePath, repeats)
    content = JSON.parse(File.read("#{sourcePath}/Contents.json"))
    content["images"].each{|item|(
      next if item["filename"].nil?
      filePath = "#{sourcePath}/#{item["filename"]}"
      sha256 = `shasum -a 256 '#{filePath}'`
      if repeats.key?(sha256)
        repeats[sha256].push(filePath)
      else
        repeats[sha256] = [filePath]
      end
    )}
  end

  def extractImageRef(sourcePath, refs)
    print "#{refs.count} \r"
    STDOUT.flush
    Dir::entries(sourcePath).each{|item|
    (
      subPath = sourcePath+"/"+item
      if File.directory?(subPath) || File.extname(subPath).eql?(".lproj")
        if !(item.eql?('.') || item.eql?('..'))
          extractImageRef(subPath, refs)
        end
      else        
        extractFor(subPath, refs)
      end
    )}

  end

  def extractFor(filePath, refs)
    file_content = File.read(filePath)
    # 查找图片引用
    if filePath.end_with?('.m')
      regex = /@"(.+?)"/
    elsif filePath.end_with?('.swift')
      regex = /"(.+?)"/
    else
      return
    end
    file_content.scan(regex) do |match|
      # binding.pry
      key = match[0]
      if refs.key?(key)
        refs[key] = 1
      else
        refs[key] = refs[key].to_i + 1
      end
    end
  end

  def collectImage(sourcePath, images)  
    if !File::exist?(sourcePath)
      return
    end
    Dir::entries(sourcePath).each{|item|
    (
      subPath = sourcePath+"/"+item
      if item.end_with?('.imageset')
        name = item.scan(/([\S\s]+).(imageset)/).first[0]
        images.push({"name" => name, "path" => subPath})
      else
        if File.directory?(subPath)
          if !(item.eql?('.') || item.eql?('..'))
          collectImage(subPath, images)
          end
        end
      end
    )}
    
  end

  # 图片混淆（修改hash）
  def imageReset(param)
    images = []
    puts "正在收集信息..."
    sleep 1
    magick = `which magick`
    if magick.include?('not found')
      puts PBUtil::error('找不到命令 imagemagick 准备开始安装...')
      `brew install imagemagick`
      return
    end
    if !param.imagePaths.nil?
      param.imagePaths.each{|item|
      (
        updateImage(item,images)
      )}
    end
    count = 0;

    puts PBUtil::info("🍺收集完成，准备处理...")
    images.each{|item|
    (
      count = count + 1
      `magick #{item} #{item}`
      print ("正在处理...#{count}/#{images.length} #{item}").ljust(220) + " \r"
      STDOUT.flush
    )}
    puts ""
    puts PBUtil::debug("处理完成，共计 #{count} 个图片更新...")
  end

  def updateImage(sourcePath, images)
    if !File::exist?(sourcePath)
      return
    end

    Dir::entries(sourcePath).each{|item|
    (
      subPath = sourcePath+"/"+item
      if File.directory?(subPath)
        if !(item.eql?('.') || item.eql?('..'))
          updateImage(subPath, images)
        end
      else
        if Image_Extension.include?(File.extname(item))
          images.push(subPath)
        end
      end
    )}
  end

end
