Pod::Spec.new do |s|
  s.name                  = "INTUGroupedArray"
  s.version               = "1.1.5"
  s.homepage              = "https://github.com/intuit/GroupedArray"
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { "Tyler Fox" => "tyler_fox@intuit.com" }
  s.source                = { :git => "https://github.com/intuit/GroupedArray.git", :tag => "v1.1.5"}
  s.source_files          = 'Source/INTUGroupedArray/**/*.{h,m}'
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'
  s.requires_arc          = true
  s.summary               = "An Objective-C and Swift collection for iOS and OS X that stores objects grouped into sections."
  s.description           = <<-DESC
  INTUGroupedArray is an Objective-C data structure that takes the common one-dimensional array to the next dimension. The grouped array is designed with a familiar API to fit right in alongside Foundation collections like NSArray, with fully-featured immutable and mutable variants. A thin bridge brings the grouped array to Swift as native classes, where it harnesses the power, safety, and flexibility of generics, optionals, subscripts, literals, tuples, and much more.

  INTUGroupedArray is extremely versatile, and can replace complicated nested arrays or combinations of other data structures as a general purpose data storage mechanism. The grouped array is ideal to use as a UITableView data source, as it is highly compatible with the data source and delegate callbacks -- requiring only a single line of code in many cases. However, it is suitable for use across the entire stack of iOS and OS X applications.
  DESC
end
