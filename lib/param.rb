#!/usr/bin/ruby -w
require 'fileutils'
require 'yaml'
require_relative './util'

Arg_Name_ConfigPath   = "--config"
ACTION_TYPE_PREFIX  = "prefix"
ACTION_TYPE_IMAGE   = "image"
ACTION_TYPE_SWITCH  = "switch"
ACTINO_TYPE_POD     = "pod"

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
  attr_accessor:arrange #整理
  attr_accessor:params #参数
  def initialize(options)
    @ignorePaths = []
    @sourceFiles = []
    @prefixMap = Hash.new
    configPath = '.toolbox.yml'
    if configPath && File.exist?(configPath)
      properties = YAML.load_file(Pathname(configPath).to_path)
      @directory = properties['directory']
      Dir.chdir(@directory)
      puts "目录变更: #{Dir.pwd}"
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
      puts PBUtil::error("缺少配置文件.toolbox.yml in #{Dir.pwd}",true)
      exit
    end
  end
end
