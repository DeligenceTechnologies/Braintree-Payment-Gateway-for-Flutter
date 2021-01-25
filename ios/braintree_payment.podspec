#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'braintree_payment'
  s.version          = '1.0.2'
  s.summary          = 'Braintree Payment plugin for Flutter apps by Deligence Technologies. This plugin lets you integrate Braintree Drop In payment UI in just 4 easy steps.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://deligence.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Deligence' => 'adarsh@deligence.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'BraintreeDropIn'
  s.dependency 'Braintree/PayPal'
  s.dependency 'Braintree/Apple-Pay'
  s.dependency 'Braintree/DataCollector'
  s.ios.deployment_target = '10.0'
  s.static_framework = true
end

