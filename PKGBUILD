pkgname=lvm-autosnap
pkgver=0.0.1
pkgrel=1
pkgdesc=''
arch=('any')
license=('MIT')
depends=('lvm2')
source=(
  'config.sh'
  'core.sh'
  'install-hook.sh'
  'lvm-wrapper.sh'
  'lvm-autosnap.env'
  'lvol.sh'
  'runtime-hook.sh'
  'util.sh'
)
backup=(etc/lvm-autosnap.env)

package() {
  # Add core scripts
  bin_dir="${pkgdir}/usr/share/lvm-autosnap"
  install -D -m0755 "${srcdir}/config.sh" "$bin_dir/config.sh"
  install -D -m0755 "${srcdir}/core.sh" "$bin_dir/core.sh"
  install -D -m0755 "${srcdir}/lvm-wrapper.sh" "$bin_dir/lvm-wrapper.sh"
  install -D -m0755 "${srcdir}/lvol.sh" "$bin_dir/lvol.sh"
  install -D -m0755 "${srcdir}/util.sh" "$bin_dir/util.sh"

  # Add default config file
  install -D -m0644 "${srcdir}/lvm-autosnap.env" "${pkgdir}/etc/lvm-autosnap.env"

  # Add the initcpio hooks
  install -D -m0644 "${srcdir}/install-hook.sh" "${pkgdir}/usr/lib/initcpio/install/lvm-autosnap"
  install -D -m0644 "${srcdir}/runtime-hook.sh" "${pkgdir}/usr/lib/initcpio/hooks/lvm-autosnap"
}

sha256sums=('c3a3e0778696f5fb3e45136d6f2b133cd1ad8db0d8e53507972c8da39e761a98'
            '5a5852999331d9df5950e2d9d7698ee04c8f1681aed2638144d27fabe1456542'
            '6da4ef35e2371f7648f59c063c26280ae197151a569959ff13485fb02ab5279e'
            'c360b15ccc512528d6aa5fe305830c59733c886ffbaf1a0f5e26fe744cf7950a'
            '2f4740be82fd099192d49239d21423b8bcbaf55831c31258f29a1b8516e34760'
            'c916b3bc0c777396f10ada7dc0b186832dc544f45db0bd4965dce18721b0a2e7'
            'e2f29d12ffe02adff1896ec88bf5dd8ee45ce103ff71fc6522791097af76c66b'
            'e541903619563c357fa3fc566e3b1f8257f40ef453ea044cadc333e620a6b917')

