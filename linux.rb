
package :kernelorg_linux do
  raise "missing environment variable KERNEL_ORG_VERSION" unless VAR['KERNEL_ORG_VERSION']
  fn = "linux-#{VAR['KERNEL_ORG_VERSION']}.tar.xz"
  dl = download "https://www.kernel.org/pub/linux/kernel/v3.x/#{fn}", fn, fn
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

