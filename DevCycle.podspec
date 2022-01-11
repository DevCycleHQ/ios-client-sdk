Pod::Spec.new do |spec|
  spec.name         = "DevCycle"
  spec.version      = "1.0.0"
  spec.summary      = "The iOS SDK for Devcycle!"

  spec.description  = <<-DESC
    The iOS SDK for Devcycle!
                   DESC

  spec.homepage     = "https://devcycle.com/"
  spec.license      = "MIT"

  spec.ios.deployment_target     = "12.0"
  spec.source = { :git => 'https://github.com/DevCycleHQ/ios-client-sdk.git', :tag => "#{spec.version}" }

  spec.author       = { "DevCycle" => "help@taplytics.com" }

  spec.source_files  = "DevCycle/**/*.{h,m,swift}"
  spec.swift_version = '5.0'

end
