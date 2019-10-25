#!/bin/bash
/opt/pbis/bin/config UserDomainPrefix "BGCDEV"
/opt/pbis/bin/config AssumeDefaultDomain "true"
/opt/pbis/bin/config HomeDirTemplate "%H/%U"
/opt/pbis/bin/config RemoteHomeDirTemplate "%H/%U"
/opt/pbis/bin/config HomeDirUmask "077"
/opt/pbis/bin/config LoginShellTemplate "/bin/bash"
/opt/pbis/bin/config Local_HomeDirTemplate "%H/%U"
/opt/pbis/bin/config Local_HomeDirUmask "077"
