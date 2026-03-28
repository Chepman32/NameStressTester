require "fileutils"
require "pathname"
require "xcodeproj"

ROOT = Pathname(__dir__).parent.expand_path
PROJECT_PATH = ROOT.join("Litmus.xcodeproj")
APP_PATH = ROOT.join("Litmus")
TESTS_PATH = ROOT.join("LitmusTests")
UI_TESTS_PATH = ROOT.join("LitmusUITests")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
project.root_object.attributes["LastUpgradeCheck"] = "1640"
project.root_object.attributes["LastSwiftUpdateCheck"] = "1640"

project.build_configuration_list.build_configurations.each do |config|
  config.build_settings["SWIFT_VERSION"] = "5.9"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
end

app_target = project.new_target(:application, "Litmus", :ios, "17.0")
unit_target = project.new_target(:unit_test_bundle, "LitmusTests", :ios, "17.0")
ui_target = project.new_target(:ui_test_bundle, "LitmusUITests", :ios, "17.0")

app_target.build_configurations.each do |config|
  config.build_settings["INFOPLIST_FILE"] = "Litmus/Resources/Info.plist"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.antonchepur.litmus"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  config.build_settings["SWIFT_OPTIMIZATION_LEVEL"] = config.name == "Debug" ? "-Onone" : "-O"
  config.build_settings["DEFINES_MODULE"] = "YES"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["MARKETING_VERSION"] = "1.0.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["ENABLE_PREVIEWS"] = "YES"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["DEVELOPMENT_TEAM"] = ""
  config.build_settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "NO"
end

unit_target.build_configurations.each do |config|
  config.build_settings["INFOPLIST_FILE"] = "LitmusTests/Info.plist"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.antonchepur.litmus.tests"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["DEVELOPMENT_TEAM"] = ""
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Litmus.app/Litmus"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

ui_target.build_configurations.each do |config|
  config.build_settings["INFOPLIST_FILE"] = "LitmusUITests/Info.plist"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.antonchepur.litmus.uitests"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["DEVELOPMENT_TEAM"] = ""
  config.build_settings["TEST_TARGET_NAME"] = "Litmus"
end

unit_target.add_dependency(app_target)
ui_target.add_dependency(app_target)

def add_entries(group, directory, source_phase:, resource_phase: nil)
  directory.children.sort_by(&:to_s).each do |entry|
    next if entry.basename.to_s.start_with?(".")

    if entry.directory?
      if entry.extname == ".xcassets"
        asset_ref = group.new_file(entry.basename.to_s)
        resource_phase&.add_file_reference(asset_ref)
        next
      end

      subgroup = group.new_group(entry.basename.to_s, entry.basename.to_s)
      add_entries(subgroup, entry, source_phase: source_phase, resource_phase: resource_phase)
      next
    end

    next if entry.basename.to_s == "Info.plist"

    file_ref = group.new_file(entry.basename.to_s)
    case entry.extname
    when ".swift"
      source_phase.add_file_reference(file_ref)
    else
      resource_phase&.add_file_reference(file_ref)
    end
  end
end

main_group = project.main_group
app_group = main_group.new_group("Litmus", "Litmus")
tests_group = main_group.new_group("LitmusTests", "LitmusTests")
ui_tests_group = main_group.new_group("LitmusUITests", "LitmusUITests")

add_entries(app_group, APP_PATH, source_phase: app_target.source_build_phase, resource_phase: app_target.resources_build_phase)
add_entries(tests_group, TESTS_PATH, source_phase: unit_target.source_build_phase, resource_phase: unit_target.resources_build_phase)
add_entries(ui_tests_group, UI_TESTS_PATH, source_phase: ui_target.source_build_phase, resource_phase: ui_target.resources_build_phase)

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_test_target(unit_target)
scheme.add_test_target(ui_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH.to_s, "Litmus", true)

project.save
puts "Generated #{PROJECT_PATH}"
