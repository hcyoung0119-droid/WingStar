require 'xcodeproj'

# Idempotent build setup for the native widget extension. Both targets share
# the exact ActivityAttributes type. No App Groups or push entitlement is used.
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
app = project.targets.find { |target| target.name == 'Runner' }
raise 'Runner target missing' unless app
runner_group = project.main_group.find_subpath('Runner', false)
attributes = runner_group.files.find { |f| f.path == 'WalkingActivityAttributes.swift' } ||
             runner_group.new_file('WalkingActivityAttributes.swift')
live = runner_group.files.find { |f| f.path == 'WalkingLiveActivity.swift' } ||
       runner_group.new_file('WalkingLiveActivity.swift')
[attributes, live].each do |file|
  app.source_build_phase.add_file_reference(file, true)
end

extension = project.targets.find { |target| target.name == 'WingstarLiveActivity' }
unless extension
  extension = project.new_target(:app_extension, 'WingstarLiveActivity', :ios, '16.2')
  group = project.main_group.new_group('WingstarLiveActivity', 'WingstarLiveActivity')
  extension.add_file_references([group.new_file('WingstarLiveActivity.swift'), attributes])
  group.new_file('Info.plist')
  app.add_dependency(extension)
  embed = app.new_copy_files_build_phase('Embed App Extensions')
  embed.dst_subfolder_spec = '13'
  embed.add_file_reference(extension.product_reference, true)
end

project.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2' }
app.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.wingstar.personal'
end
extension.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.wingstar.personal.walking',
    'INFOPLIST_FILE' => 'WingstarLiveActivity/Info.plist',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.2',
    'TARGETED_DEVICE_FAMILY' => '1',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'SKIP_INSTALL' => 'YES',
    'CODE_SIGN_STYLE' => 'Automatic',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  })
end
project.save
