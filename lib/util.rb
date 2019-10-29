#!/usr/bin/ruby -w
require 'fileutils'
require 'json'

# author: Rake Yang
# 日志输出
# 2019-10-29
class PBUtil
  # 提醒
  def self.warn(msg)
    return "\033[32m#{msg}\033[0m"
  end

  # 信息
  def self.info(msg)
    return "\033[37m#{msg}\033[0m"
  end

  # 调试
  def self.debug(msg)
    return "\033[35m#{msg}\033[0m"
  end

  # 错误
  def self.error(msg, newline = false)
    return newline ? "\033[31m#{msg}\033[0m\n":"\033[31m#{msg}\033[0m"
  end
end
