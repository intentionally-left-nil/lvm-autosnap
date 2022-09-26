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
  'lvm-autosnap.env'
  'lvm-autosnap.service'
  'lvm-autosnap.timer'
  'lvm-wrapper.sh'
  'lvol.sh'
  'runtime-hook.sh'
  'service.sh'
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
  install -D -m0755 "${srcdir}/service.sh" "$bin_dir/service.sh"
  install -D -m0755 "${srcdir}/util.sh" "$bin_dir/util.sh"

  # Add default config file
  install -D -m0644 "${srcdir}/lvm-autosnap.env" "${pkgdir}/etc/lvm-autosnap.env"

    # Add service to mark snapshots as not-pending once successfully booted
  install -D -m0644 "${srcdir}/lvm-autosnap.service" "${pkgdir}/usr/lib/systemd/system/lvm-autosnap.service"
  install -D -m0644 "${srcdir}/lvm-autosnap.timer" "${pkgdir}/usr/lib/systemd/system/lvm-autosnap.timer"

  # Add the initcpio hooks
  install -D -m0644 "${srcdir}/install-hook.sh" "${pkgdir}/usr/lib/initcpio/install/lvm-autosnap"
  install -D -m0644 "${srcdir}/runtime-hook.sh" "${pkgdir}/usr/lib/initcpio/hooks/lvm-autosnap"
}

sha256sums=('747e34fb2248df26a03dcfc49f927347278f2c73a7223462e58acee95c6e38e7'
            'e4d65ff7c4485ce65aa0d848a71511fd3798c1b6e59486d07240c14194498655'
            '6da4ef35e2371f7648f59c063c26280ae197151a569959ff13485fb02ab5279e'
            '2f4740be82fd099192d49239d21423b8bcbaf55831c31258f29a1b8516e34760'
            'd5161e6c7caa070f0ef7e527be1a0003415337f285ab5191d4bbdacf0bf42bb0'
            'e8da40587043edc18744bd23b844edfac95f6766cf6b397fce5ddbb3560401c2'
            'ec8f66677f43fee64cf374fdb8a944985d20be40fbfde5b17bbc0d8fa13d2f28'
            '7f19400375604b31e07fce152da2dfb7cb9fe1dd5f505c40e1d83cf16aa1dec2'
            'e2f29d12ffe02adff1896ec88bf5dd8ee45ce103ff71fc6522791097af76c66b'
            'c5799a28c5006e2dbb47d2a27c6eca8526e6e241de0479a6688c484772e8a62f'
            'e3c6f388a0f39ff8f29dcee51796fd05911cb27d9642c1d734f8d3965d5031b3')

