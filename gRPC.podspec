Pod::Spec.new do |s|
  s.name     = 'gRPC'
  s.version  = '0.5.1'
  s.summary  = 'gRPC client library for iOS/OSX'
  s.homepage = 'http://www.grpc.io'
  s.license  = 'New BSD'
  s.authors  = { 'The gRPC contributors' => 'grpc-packages@google.com' }

  # s.source = { :git => 'https://github.com/grpc/grpc.git',
  #              :tag => 'release-0_9_1-objectivec-0.5.1' }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  # Reactive Extensions library for iOS.
  s.subspec 'RxLibrary' do |rs|
    rs.source_files = 'src/objective-c/RxLibrary/*.{h,m}',
                      'src/objective-c/RxLibrary/transformations/*.{h,m}',
                      'src/objective-c/RxLibrary/private/*.{h,m}'
    rs.private_header_files = 'src/objective-c/RxLibrary/private/*.h'
  end

  # Core cross-platform gRPC library, written in C.
  s.subspec 'C-Core' do |cs|
    cs.source_files = 'src/core/**/*.{h,c}', 'include/grpc/*.h', 'include/grpc/**/*.h'
    cs.private_header_files = 'src/core/**/*.h'
    cs.header_mappings_dir = '.'
    # The core library includes its headers as either "src/core/..." or "grpc/...", meaning we have
    # to tell XCode to look for headers under the "include" subdirectory too.
    #
    # TODO(jcanizales): Instead of doing this, during installation move everything under
    # "include/grpc" one directory up. The directory names under PODS_ROOT are implementation
    # details of Cocoapods, and have changed in the past, breaking this podspec.
    cs.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/Headers/Private/gRPC" ' +
                                             '"$(PODS_ROOT)/Headers/Private/gRPC/include"' }
    cs.compiler_flags = '-GCC_WARN_INHIBIT_ALL_WARNINGS', '-w'

    cs.requires_arc = false
    cs.libraries = 'z'
    cs.dependency 'OpenSSL', '~> 1.0.200'
  end

  # This is a workaround for Cocoapods Issue #1437.
  # It renames time.h and string.h to grpc_time.h and grpc_string.h.
  # It needs to be here (top-level) instead of in the C-Core subspec because Cocoapods doesn't run
  # prepare_command's of subspecs.
  #
  # TODO(jcanizales): Try out Todd Reed's solution at Issue #1437.
  s.prepare_command = <<-CMD
    DIR_TIME="grpc/support"
    BAD_TIME="$DIR_TIME/time.h"
    GOOD_TIME="$DIR_TIME/grpc_time.h"
    grep -rl "$BAD_TIME" include/grpc src/core | xargs sed -i '' -e s@$BAD_TIME@$GOOD_TIME@g
    if [ -f "include/$BAD_TIME" ];
    then
      mv -f "include/$BAD_TIME" "include/$GOOD_TIME"
    fi

    DIR_STRING="src/core/support"
    BAD_STRING="$DIR_STRING/string.h"
    GOOD_STRING="$DIR_STRING/grpc_string.h"
    grep -rl "$BAD_STRING" include/grpc src/core | xargs sed -i '' -e s@$BAD_STRING@$GOOD_STRING@g
    if [ -f "$BAD_STRING" ];
    then
      mv -f "$BAD_STRING" "$GOOD_STRING"
    fi
  CMD

  # Objective-C wrapper around the core gRPC library.
  s.subspec 'GRPCClient' do |gs|
    gs.source_files = 'src/objective-c/GRPCClient/*.{h,m}',
                      'src/objective-c/GRPCClient/private/*.{h,m}'
    gs.private_header_files = 'src/objective-c/GRPCClient/private/*.h'
    gs.compiler_flags = '-GCC_WARN_INHIBIT_ALL_WARNINGS', '-w'

    gs.dependency 'gRPC/C-Core'
    # TODO(jcanizales): Remove this when the prepare_command moves everything under "include/grpc"
    # one directory up.
    gs.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/Headers/Public/gRPC/include"' }
    gs.dependency 'gRPC/RxLibrary'

    # Certificates, to be able to establish TLS connections:
    gs.resource_bundles = { 'gRPC' => ['etc/roots.pem'] }
  end

  # RPC library for ProtocolBuffers, based on gRPC
  s.subspec 'ProtoRPC' do |ps|
    ps.source_files = 'src/objective-c/ProtoRPC/*.{h,m}'

    ps.dependency 'gRPC/GRPCClient'
    ps.dependency 'gRPC/RxLibrary'
    ps.dependency 'Protobuf', '~> 3.0.0-alpha-3'
  end
end
