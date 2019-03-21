PACKAGE=pve-edk2-firmware
# version and package release is controlled over d/changelog
VER=$(shell dpkg-parsechangelog -S version)

SRCDIR=edk2
BUILDDIR=${SRCDIR}.build

GITVERSION:=$(shell git rev-parse HEAD)

DEB=${PACKAGE}_${VER}_all.deb

all: ${DEB}
	@echo ${DEB}

.PHONY: deb
deb: ${DEB}
${DEB}: | submodule
	rm -rf ${BUILDDIR}
	cp -rpa ${SRCDIR} ${BUILDDIR}
	cp -a debian ${BUILDDIR}
	echo "git clone git://git.proxmox.com/git/pve-edk2-firmware.git\\ngit checkout ${GITVERSION}" > ${BUILDDIR}/debian/SOURCE
	cd ${BUILDDIR}; dpkg-buildpackage -b -uc -us
	lintian ${DEB}
	@echo ${DEB}

.PHONY: submodule
submodule:
	test -f "${SRCDIR}/Readme.md" || git submodule update --init --recursive

.PHONY: update_modules
update_modules: submodule
	git submodule foreach 'git pull --ff-only origin master'

.PHONY: upload
upload: ${DEB}
	tar cf - ${DEB}|ssh -X repoman@repo.proxmox.com -- upload --product pve --dist stretch

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *.deb ${BUILDDIR} *.changes *.dsc *.buildinfo

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}
