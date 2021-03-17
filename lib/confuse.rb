#!/usr/bin/ruby -w
require 'fileutils'
require_relative './util'
require 'json'
require 'xcodeproj'

OC_Extension          = [".h", ".mm", ".m", ".xib", ".storyboard", ".pch", ".swift"]
Image_Extension       = [".png", ".jpg", ".jpeg"]
Ignore_Files          = ["main.m", "main.mm"]

# author: Rake Yang
# 混淆：修改类名、修改图片hash
# 2019-10-29
class PBConfuse
  attr_accessor:sourceFiles
  attr_accessor:prefixMap
  attr_accessor:includeCategory
  attr_accessor:projectPath
  def initialize(param)
    @prefixMap = param.prefixMap
    @sourceFiles = param.sourceFiles
    @includeCategory = param.includeCategory
    @projectPath = param.projectPath
    prefixAction(param)
  end

  def prefixAction(param)
    param.sourcePaths.each{|item|
      (
        if File::exist?(item)
          replaceFileClassName(Pathname("#{item}").to_path, param)
        else
          puts PBUtil::error("文件夹不存在 #{item}")
        end
      )}
    puts ""
    puts PBUtil::debug("共计 #{param.sourceFiles.count} 项完成重命名...")
    replaceProject(param)
    replacePodfile(param)
  end

  # 替换类名前缀
  def replaceFileClassName(sourcePath, param)
    Dir::entries(sourcePath).each{|item|(
      subPath = sourcePath+"/"+item
      if File.directory?(subPath) || File.extname(subPath).eql?(".lproj")
        if !(item.eql?('.') || item.eql?('..'))
          replaceFileClassName(subPath, param)
        end
      else
          replaceClassPrefix(subPath, param)
      end
      )}
  end

  def replaceClassPrefix(file, param)
    if File::exist?(file) && OC_Extension.include?(File.extname(file))
      if (@includeCategory.nil? || !@includeCategory) && !File.basename(file).match(/\+\b(\w+)\b/).nil?
        # puts Confuse::debug("忽略类别 #{file}")
        addMapping(file, file)
        return
      end
      if param.ignorePaths.select { |e| file.gsub(/#{Dir.pwd}/, "").start_with?(e) }.length > 0 || File.extname(file).eql?(".pch")
        # 忽略的文件需要替换内容
        # pch不重命名
        addMapping(file, file)
        return
      end
      fileName = File.basename(file)
      if Ignore_Files.include?(fileName)
        addMapping(file, file)
      elsif fileName.start_with?(param.old_prefix)
        newName = File.dirname(file) + '/' + param.new_prefix + fileName[param.old_prefix.length, fileName.length-param.old_prefix.length]
        # File.rename(file, newName)
        `git mv -k #{file} #{newName}`
        addMapping(file, newName)
      elsif !fileName.start_with?(param.new_prefix)
        newName = File.dirname(file) + '/' + param.new_prefix + fileName
        # File.rename(file, newName)
        `git mv -k #{file} #{newName}`
        addMapping(file, newName)
      else
        addMapping(file, file)
      end
    end
  end

  def replaceProject(param)
    puts "开始更新文件内容引用..."
    fileIndex = 0
    param.sourceFiles.each{|filePath|
      (
        nFile = File.read(filePath)
        nBuffer = nFile
        # TODO:匹配文件中所有的类名看是否需要替换（提升效率）
        param.prefixMap.each{|key,value|
          (
            # 替换import，不支持<xxxxx.h>
            nBuffer = nBuffer.gsub(/([\/\"])(\b#{key}\b)([^\/\+])/) do |match1|
              match1.gsub($~[2], "#{value}")
            end

            # 替换内容
            nBuffer = nBuffer.gsub(/([^\/\+#"])(\b#{key}\b)([^\/+])/) do |match2|
              match2.gsub($~[2], "#{value}")
            end
          )}

        if File.extname(filePath).eql?(".xib")
          nBuffer = nBuffer + "\n"
        end
        if !nFile.eql?(nBuffer)
          File.open(filePath, "r+") do |aFile|
            aFile.syswrite(nBuffer)
         end
         print PBUtil::warn("更新 #{fileIndex}\/#{sourceFiles.count} #{filePath.gsub(/#{Dir.pwd}\//,"")}").ljust(200)+" \r"
         STDOUT.flush
        end
        fileIndex = fileIndex+1

      )}

    puts PBUtil::warn("共计 #{@sourceFiles.length} 完成更新...")
    buffer = File.read("#{projectPath}/project.pbxproj")
    @prefixMap.each{|key,value|
      (
        buffer = buffer.gsub(/([^+])(\b#{key}\b)([.])/) do |match|
          match.gsub($~[2], "#{value}")
        end
      )}

   File.open("#{@projectPath}/project.pbxproj", "w") do |aFile|
      aFile.syswrite(buffer)
      puts "更新 " + PBUtil::warn("#{@projectPath}/project.pbxproj")
   end

   puts PBUtil::error("PS: 请先提交重命名的文件，再提交内容变更的文件!!!🍺")

  end

  def replacePodfile(param)
    if param.podfile.nil?
      return
    end
    puts "更新\t" + Confuse::warn(param.podfile)
    buffer = File.read("#{param.podfile}")
    @prefixMap.each{|key,value|(
      if buffer.nil?
        puts "#{key} #{value}"
      end
        buffer = buffer.gsub(/"\b#{key}\b/, value)
      )}
    File.write("#{param.podfile}", buffer)
  end

  # 添加映射关系
  def addMapping(oldPath, newPath)
    if !@sourceFiles.include?(newPath)
      @sourceFiles.push(newPath)
    end
    oldName = File.basename(oldPath, File.extname(oldPath))
    newName = File.basename(newPath, File.extname(newPath))
    if !@prefixMap.has_key?(oldName)
      @prefixMap[oldName] = newName
      # internalClass(newPath)
      if !oldPath.eql?(newPath)
        path = oldPath.gsub(/#{Dir.pwd}\//,"")
        print PBUtil::debug("重命名 #{path}").ljust(200) + " \r"
        STDOUT.flush
      end
    end

  end

  # 内部类(和文件名不同)
  def internalClass(filePath)

    buffer = File.read('newPath')
    # 逆序环视
    buffer.match(/(?<=@interface)\s+\b\w+\b/).to_a.each
  end

end
