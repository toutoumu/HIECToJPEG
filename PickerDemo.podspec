Pod::Spec.new do |s|
  s.name         = 'PickerDemo'
  s.version      = '1.5.3'
  s.license      = '<#License#>'
  s.homepage     = '<#Homepage URL#>'
  s.authors      = '<#Author Name#>': '<#Author Email#>'
  s.summary      = '<#Summary (Up to 140 characters#>'

  s.platform     =  :ios, '<#iOS Platform#>'
  s.source       =  git: '<#Github Repo URL#>', :tag => s.version
  s.source_files = '<#Resources#>'
  s.frameworks   =  '<#Required Frameworks#>'
  s.requires_arc = true
  
# Pod Dependencies
  s.dependencies =	pod 'GPUImage', :head
  s.dependencies =	pod 'NBULog'
  s.dependencies =	pod 'LumberjackConsole'
  s.dependencies =	pod "MWPhotoBrowser"
  s.dependencies =	pod 'NBUImagePicker', :path => '../'

end