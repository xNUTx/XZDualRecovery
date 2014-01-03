#!/bin/bash

togglerelease() {
	if [ "$RELEASE" = "BETA" ]; then
		setrelease
	else
		setbeta
	fi
}

setbeta() {
	echo "BETA" > ${WORKDIR}/scripts/release
	RELEASE=`cat ${WORKDIR}/scripts/release`
	echo "Using the release label: ${RELEASE}."
	sleep 2
}

setrelease() {
	echo "RELEASE" > ${WORKDIR}/scripts/release
	RELEASE=`cat ${WORKDIR}/scripts/release`
	echo "Using the release label: ${RELEASE}."
	sleep 2
}

getlabel() {
	RELEASE=`cat ${WORKDIR}/scripts/release`
	echo "Using the release label: ${RELEASE}."
	sleep 2
}

incrmajor() {
	MAJOR=$((MAJOR + 1))
	MINOR=0
	REVISION=0
	echo "Setting Locked Dual Recovery version ${MAJOR}.${MINOR}.${REVISION}..."
	echo ${MAJOR} > ${WORKDIR}/scripts/version
	echo ${MINOR} > ${WORKDIR}/scripts/minor
	echo ${REVISION} > ${WORKDIR}/scripts/revision
	sleep 2
}

incrminor() {
	MINOR=$((MINOR + 1))
	REVISION=0
	echo "Setting Locked Dual Recovery version ${MAJOR}.${MINOR}.${REVISION}..."
	echo ${MINOR} > ${WORKDIR}/scripts/minor
	echo ${REVISION} > ${WORKDIR}/scripts/revision
	sleep 2
}

incrrevision() {
	REVISION=$((REVISION + 1))
	echo "Setting Locked Dual Recovery version ${MAJOR}.${MINOR}.${REVISION}..."
	echo ${REVISION} > ${WORKDIR}/scripts/revision
	sleep 2
}

getversion() {
	echo "Using Locked Dual Recovery version ${MAJOR}.${MINOR}.${REVISION}..."
	sleep 2
}
