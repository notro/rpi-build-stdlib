
def kernelorg_linux_latest
  url = 'https://www.kernel.org/finger_banner'
  s = http_get url
  fn = nil
  m = s.match(/The latest stable ([\d\.]+) version of the Linux kernel is:\s+(\d+\.\d+\.\d+.*)$/)
  unless m
    puts s
    raise "Could not get latest mainline version number from #{url}"
  end
  m[2]
end

package :kernelorg_linux do
  raise "missing environment variable KERNEL_ORG_VERSION" unless VAR['KERNEL_ORG_VERSION']
  fn = "linux-#{VAR['KERNEL_ORG_VERSION']}.tar.xz"
  major = VAR['KERNEL_ORG_VERSION'].split('.')[0]
  dl = download "https://www.kernel.org/pub/linux/kernel/v#{major}.x/#{fn}", fn, fn

  t = file download_dir("#{fn}.sha") do |t|
    next if VAR['KERNEL_ORG_SKIP_SHA'] == '1'
    sums_url = "https://www.kernel.org/pub/linux/kernel/v#{major}.x/sha256sums.asc"
    info "Create #{t.name} from #{sums_url}"
    sums = http_get sums_url
    m = sums.match(/([0-9a-f]+ .#{fn})/)
    raise "Could not get '#{fn}' shasum from #{sums_url}\nSkip this with: KERNEL_ORG_SKIP_SHA=1" unless m
    File.write t.name, "#{m[1]}\n"
  end
  dl.enhance [t.name]

  un = unpack fn, 'linux'
  un.enhance [dl.name]

  ENV['LINUX_DEFCONFIG'] ||= 'bcm2835_defconfig'
  config ['CONFIG_IKCONFIG', 'CONFIG_IKCONFIG_PROC'], :enable
  config 'PROC_DEVICETREE', :enable

  target :kbuild do
    post_install <<EOM
cp "${FW_REPOLOCAL}/zImage" "${FW_PATH}/"

EOM
	end

  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    msrc = workdir 'modules'

    cp(ksrc + "/arch/arm/boot/zImage", dst)
    sh "cp #{ksrc}/arch/arm/boot/dts/*.dtb #{dst}"
    mkdir_p(dst + "/modules")
    sh "cp -r #{msrc}/lib/modules/* #{dst}/modules/" unless FileList["#{msrc}/lib/modules/*"].empty?
    sh "cp -r #{msrc}/lib/firmware #{dst}/" unless FileList["#{msrc}/lib/firmware/*"].empty?
    cp(ksrc + "/Module.symvers", dst)
    mkdir_p(dst + "/extra")
    cp(ksrc + "/System.map", dst + "/extra/")
    cp(ksrc + "/.config", dst + "/extra/")
  end

end

