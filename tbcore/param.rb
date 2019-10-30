#!/usr/bin/ruby -w
require 'fileutils'
require 'yaml'
require_relative './util'

Arg_Name_ConfigPath   = "--config"
ACTION_TYPE_PREFIX  = "prefix"
ACTION_TYPE_IMAGE   = "image"
ACTION_TYPE_SWITCH  = "switch"

# author: Rake Yang
# 参数、配置文件解析
# 2019-10-29
class PBParam
  attr_accessor:directory   # 工作目录
  attr_accessor:projectPath # 项目文件目录
  attr_accessor:sourcePaths # 源码目录列表
  attr_accessor:imagePaths  # 图片目录列表
  attr_accessor:old_prefix  # 之前前缀
  attr_accessor:new_prefix  # 新前缀
  attr_accessor:ignorePaths # 忽略目录列表
  attr_accessor:prefixMap   # 替换的映射表
  attr_accessor:sourceFiles # 源码文件列表
  attr_accessor:includeCategory # 包含类别
  attr_accessor:podfile     # podfile
  attr_accessor:actionType  # 命令类型
  attr_accessor:bundle  #App配置
  def initialize(args)
    @ignorePaths = []
    @sourceFiles = []
    @prefixMap = Hash.new

    @actionType = args[0]
    if @actionType.nil? || ![ACTION_TYPE_IMAGE, ACTION_TYPE_SWITCH, ACTION_TYPE_PREFIX].include?(@actionType)
      showUsage()
      return
    end
    configPath = args[1].eql?(Arg_Name_ConfigPath) ? args[2] : '.toolbox.yml'
    if configPath && File.exist?(configPath)
      properties = YAML.load_file(Pathname(configPath).to_path)
      @directory = properties['directory']
      Dir.chdir(@directory)
      @projectPath = properties['project']
      @sourcePaths = properties['sourcePaths']
      @ignorePaths = properties['ignorePaths']||[]
      @imagePaths  = properties["imagePaths"]
      @includeCategory = properties['includeCategory']
      @podfile = properties['podfile']
      @old_prefix = properties['prefix'].split("=").first
      @new_prefix = properties['prefix'].split("=").last
      @bundle = properties['bundle']
    else
      puts PBUtil::error("缺少参数#{Arg_Name_ConfigPath}且者找不到默认文件.toolbox.yml #{Dir.pwd}",true)
      PBParam::showUsage()
    end
  end

  def showUsage()
    puts "用法: command #{PBUtil::warn('[选项]')}

命令:
    image         修改图片hash
    prefix        修改类目前缀,暂不支持内部类
    switch        切换App（马甲包）

选项:
    --config      配置文件目录（不带参数时，默认读取当前文件夹下的.toolbox.yml）
    "
  end

end
