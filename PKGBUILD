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

sha256sums=('ccca6aed23f9d61b7f8996a443716911269632d0e86805c00a201b54ff8f330f'
            '83dab194c04af2552cf2246d787ed01360452918ed4682a5f9732e5175f69511'
            '6da4ef35e2371f7648f59c063c26280ae197151a569959ff13485fb02ab5279e'
            '2f4740be82fd099192d49239d21423b8bcbaf55831c31258f29a1b8516e34760'
            'd5161e6c7caa070f0ef7e527be1a0003415337f285ab5191d4bbdacf0bf42bb0'
            'e8da40587043edc18744bd23b844edfac95f6766cf6b397fce5ddbb3560401c2'
            'ade29e0f5cb34763bc155424494878d797b7e93428bd964e3192660e9be446b7'
            '606ecfb9c034ddf7b893cc3bda481a4b1c96ad99f616bb272e6191d308ad0b4e'
            'e2f29d12ffe02adff1896ec88bf5dd8ee45ce103ff71fc6522791097af76c66b'
            'f8b7b42ce4ec533e69ffcedab2558c4e3a928b93170191c738fe516c97bd4d83'
            '5507027ba0f8ce3c0d8ea1b5cce6f291255d173ed150a00bfb3cc16cbdb8221c')

