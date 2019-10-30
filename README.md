# PBToolBox
iOS项目工具箱（iOS project tool box)

## 主要功能

- 修改文件和类名前缀
- 修改图片hash
- 一键切换App

## 安装

```ruby
brew tap binaryparadise/formula
brew install toolbox
```

## 配置文件

```ymal
directory: ToolboxExample #工作目录
project: ToolboxExample.xcodeproj #项目文件
sourcePaths:  #源码目录列表
  - Example
imagePaths: #图片目录列表
prefix: RY=BP #旧前缀=新前缀
ignorePaths: #忽略的文件夹列表
  - Verdars
includeCategory: false  #是否忽略类别（暂未支持）
bundle: # 切换App配置
 resources: #替换的资源列表
  - Images.xcassets: Example #资源位置:目标位置
 configurations:
  - name: com.binaryparadise.demo1  # 主Target的bundleid
    product_name: 工具箱 #App名称
    team_id: 8FOLMNQA
    schemes:
    - name: ToolboxExample_Example # scheme名称
      bundleid: com.binaryparadise.demo1
      profiles: # 描述文件
        Debug: cbd_dev
        Release: cbd_distribution
    - name: ToolboxExample_Example1
      bundleid: com.binaryparadise.demo2
      profiles:
        Debug: cbd_dev1
        Release: cbd_distribution1
  - name: com.binaryparadise.demo2
    product_name: Toolbox
    team_id: CEPQGFME9
    schemes:
    - name: ToolboxExample_Example
      bundleid: com.binaryparadise.demo2
      profiles:
        Debug: cbd_dev
        Release: cbd_distribution

```

## 使用

```ruby
# 查看使用帮助
toolbox
```
