#!/usr/bin/ruby -w
require 'fileutils'
require_relative './util'
require 'json'
require 'xcodeproj'

# author: Rake Yang
# 切换App配置
# 2019-10-29
class PBSwitch
  def initialize(param)
    doAction(param)
  end

  def doAction(param)
    index = 0
    param.bundle['configurations'].each{|key,value|(
      index = index + 1
      puts PBUtil.warn("#{index}.#{key['product_name']}")
      )}
    toidx = choose(param.bundle['configurations'].count)
    exchangeTo(param, toidx)
  end

  def choose(max)
    puts PBUtil.info("请选择[1-#{max}]:")
    toidx = Integer(STDIN.gets)
    if toidx < 1 || toidx > max
      puts PBUtil.error("输出错误，请重试")
      choose(max)
    end
    return toidx
  end

  def exchangeTo(param, index)
    puts PBUtil.debug("替换bundle等App信息")
    project = Xcodeproj::Project.open(param.projectPath)
    config = param.bundle['configurations'][index-1]
    config['schemes'].each{|scheme|(
      target = project.targets.select{|t| t.name.eql?(scheme['name'])}.first
      if target.nil?
        next
      end
      target.build_configurations.each{|buildc| (
        buildc.build_settings['DEVELOPMENT_TEAM'] = config['team_id']
        buildc.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = scheme['bundleid']
        buildc.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = scheme['profiles'][buildc.name]
        info_plist = buildc.build_settings['INFOPLIST_FILE'].gsub(/\$\(SRCROOT\)\//, "")
          # App显示名称
          `/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName #{config['product_name']}" #{info_plist}`
          # BundleID
          preidentifier = `/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" #{info_plist}`
          if preidentifier.include?("$(PRODUCT_BUNDLE_IDENTIFIER)")
          else
            `/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier #{scheme['bundleid']}" #{info_plist}`
          end
          if target.product_type.eql?('com.apple.product-type.application.watchapp2')
            # Apple Watch
            `/usr/libexec/PlistBuddy -c "Set :WKCompanionAppBundleIdentifier #{config['name']}" #{info_plist}`
          end
        )}
    )}
    project.save()
    copyResources(param, config)
  end

  def copyResources(param, config)
    puts PBUtil.debug("替换资源文件")
    param.bundle['resources'].each{|res| (
        shell = "cp -R bundles/#{config['name']}/#{res.keys.first} #{res.values.first}"
        # puts shell
        `#{shell}`
    )}
  end

end
