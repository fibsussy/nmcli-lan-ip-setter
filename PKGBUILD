# Maintainer: fibsussy
pkgname=nmcli-lan-ip-setter
pkgver=0.1.r1.beada7d
pkgrel=1
pkgdesc="NetworkManager dispatcher script to set preferred IP"
arch=('any')
url="https://github.com/fibsussy/$pkgname"
license=('GPL')
depends=('networkmanager' 'bash')
makedepends=('git')
source=("git+$url.git")
sha256sums=('SKIP')

pkgver() {
  cd "$srcdir/$pkgname"
  printf "0.1.r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  install -Dm755 "$srcdir/$pkgname/10-set_prefered_ip.sh" "$pkgdir/etc/NetworkManager/dispatcher.d/10-set_prefered_ip.sh"
}
