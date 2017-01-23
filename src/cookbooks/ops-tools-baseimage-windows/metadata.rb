name 'ops-tools-baseimage-windows'
maintainer '${CompanyName} (${CompanyUrl})'
maintainer_email '${EmailDocumentation}'
license 'Apache v2.0'
description 'Configures an operating system for inclusion into a VM image.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '${VersionSemantic}'

depends 'windows', '>= 1.44.1'
depends 'wsus-client', '>= 1.2.1'
