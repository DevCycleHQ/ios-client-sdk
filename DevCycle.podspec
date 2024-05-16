Pod::Spec.new do |spec|
  spec.name         = "DevCycle"
  spec.version = "1.17.2"
  spec.summary      = "The iOS SDK for Devcycle!"

  spec.description  = <<-DESC
    The iOS Client SDK for DevCycle.
                   DESC

  spec.homepage     = "https://devcycle.com/"
  spec.license = { :type => "MIT", :file => "LICENSE.txt" }

  spec.macos.deployment_target   = "10.13"
  spec.tvos.deployment_target    = "12.0"
  spec.watchos.deployment_target = "7.0"
  spec.ios.deployment_target     = "12.0"
  spec.source = { :git => 'https://github.com/DevCycleHQ/ios-client-sdk.git', :tag => "v#{spec.version}" }

  spec.author       = { "DevCycle" => "help@taplytics.com" }

  spec.source_files  = "DevCycle/**/*.{h,m,swift}"
  spec.swift_version = '5.0'

  spec.dependency 'LDSwiftEventSource', '~> 3.0'

end
