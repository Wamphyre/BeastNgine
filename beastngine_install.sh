#!/bin/bash

clear

echo "=====BeastNgine Server for FreeBSD====="

echo "----------------------by Wamphyre"

echo ""

sleep 3

echo "Updating packages..."

echo ""

pkg update && pkg upgrade -y 

echo ""

echo "Packages updated" 

echo ""

echo "Extracting ports..."

echo ""

portsnap fetch auto

echo "INSTALLING VARNISH + CERTBOT + PHP80 + MARIADB + SSHGUARD"

pkg install -y php80 php80-mysqli php80-session php80-xml php80-hash php80-ftp php80-curl php80-tokenizer php80-zlib php80-zip php80-filter php80-gd php80-openssl php80-pdo php80-bcmath php80-exif php80-fileinfo php80-pecl-imagick-im7 php80-curl

pkg install -y mariadb105-client mariadb105-server

pkg install -y py38-certbot-nginx

pkg install -y py38-salt

pkg install -y nano htop git libtool automake autoconf curl geoip

pkg install -y varnish6

cd /usr/ports/security/sshguard

make install clean BATCH=yes

mv /usr/local/etc/sshguard.conf /usr/local/etc/sshguard_bk

cd /usr/local/etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/sshguard.conf

pkg install -y libxml2 libxslt modsecurity3 python git binutils pcre libgd openldap-client

echo ""

echo "INSTALLING NGINX WITH MODSECURITY3 AND BROTLI MODULES"

sleep 5

cd

fetch https://github.com/Wamphyre/BeastNgine/raw/master/nginx-devel-1.20.0.txz && pkg install -y nginx-devel-1.20.0.txz

sleep 3

rm -rf nginx-devel-1.20.0.txz

cd /tmp

git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git

cd owasp-modsecurity-crs/

cp crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf

mkdir /usr/local/etc/modsecurity/crs

cp rules/* /usr/local/etc/modsecurity/crs

echo 'Include "/usr/local/etc/modsecurity/crs/*.conf"' >> /usr/local/etc/modsecurity/modsecurity.conf

mv /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf_OFF

cd /usr/local/etc/modsecurity

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.txt

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.conf

cd /usr/local/etc/modsecurity && touch unicode.mapping

echo "1250  (ANSI - Central Europe)
 
 00a1:21 00a2:63 00a3:4c 00a5:59 00aa:61 00b2:32 00b3:33 00b9:31 00ba:6f 00bc:31 00bd:31 00be:33 00c0:41 00c3:41 00c5:41 00c6:41 00c8:45 00ca:45 00cc:49 00cf:49 00d1:4e 00d2:4f 00d5:4f 00d8:4f 00d9:55 00db:55 00e0:61 00e3:61 00e5:61 00e6:61 00e8:65 00ea:65 00ec:69 00ef:69 00f1:6e 00f2:6f 00f5:6f 00f8:6f 00f9:75 00fb:75 00ff:79 0100:41 0101:61 0108:43 0109:63 010a:43 010b:63 0112:45 0113:65 0114:45 0115:65 0116:45 0117:65 011c:47 011d:67 011e:47 011f:67 0120:47 0121:67 0122:47 0123:67 0124:48 0125:68 0126:48 0127:68 0128:49 0129:69 012a:49 012b:69 012c:49 012d:69 012e:49 012f:69 0130:49 0131:69 0134:4a 0135:6a 0136:4b 0137:6b 013b:4c 013c:6c 0145:4e 0146:6e 014c:4f 014d:6f 014e:4f 014f:6f 0152:4f 0153:6f 0156:52 0157:72 015c:53 015d:73 0166:54 0167:74 0168:55 0169:75 016a:55 016b:75 016c:55 016d:75 0172:55 0173:75 0174:57 0175:77 0176:59 0177:79 0178:59 0180:62 0191:46 0192:66 0197:49 019a:6c 019f:4f 01a0:4f 01a1:6f 01ab:74 01ae:54 01af:55 01b0:75 01b6:7a 01c0:7c 01c3:21 01cd:41 01ce:61 01cf:49 01d0:69 01d1:4f 01d2:6f 01d3:55 01d4:75 01d5:55 01d6:75 01d7:55 01d8:75 01d9:55 01da:75 01db:55 01dc:75 01de:41 01df:61 01e4:47 01e5:67 01e6:47 01e7:67 01e8:4b 01e9:6b 01ea:4f 01eb:6f 01ec:4f 01ed:6f 01f0:6a 0261:67 02b9:27 02ba:22 02bc:27 02c4:5e 02c6:5e 02c8:27 02cb:60 02cd:5f 02dc:7e 0300:60 0302:5e 0303:7e 030e:22 0331:5f 0332:5f 037e:3b 04bb:68 0589:3a 066a:25 2000:20 2001:20 2002:20 2003:20 2004:20 2005:20 2006:20 2010:2d 2011:2d 2032:27 2035:60 203c:21 2044:2f 2074:34 2075:35 2076:36 2077:37 2078:38 2080:30 2081:31 2082:32 2083:33 2084:34 2085:35 2086:36 2087:37 2088:38 2089:39 2102:43 2107:45 210a:67 210b:48 210c:48 210d:48 210e:68 2110:49 2111:49 2112:4c 2113:6c 2115:4e 2118:50 2119:50 211a:51 211b:52 211c:52 211d:52 2124:5a 2128:5a 212a:4b 212c:42 212d:43 212e:65 212f:65 2130:45 2131:46 2133:4d 2134:6f 2191:5e 2194:2d 2195:7c 21a8:7c 2212:2d 2215:2f 2216:5c 2217:2a 221f:4c 2223:7c 2236:3a 223c:7e 2303:5e 2329:3c 232a:3e 2502:2d 250c:2d 2514:4c 2518:2d 251c:2b 2524:2b 252c:54 2534:2b 253c:2b 2550:3d 2554:2d 255a:4c 255d:2d 2566:54 256c:2b 2580:2d 2584:2d 2588:2d 2591:2d 2592:2d 2593:2d 25ac:2d 25b2:5e 25ba:3e 25c4:3c 25cb:30 25d9:30 263c:30 2640:2b 2642:3e 266a:64 266b:64 2758:7c 3000:20 3008:3c 3009:3e 301a:5b 301b:5d ff01:21 ff02:22 ff03:23 ff04:24 ff05:25 ff06:26 ff07:27 ff08:28 ff09:29 ff0a:2a ff0b:2b ff0c:2c ff0d:2d ff0e:2e ff0f:2f ff10:30 ff11:31 ff12:32 ff13:33 ff14:34 ff15:35 ff16:36 ff17:37 ff18:38 ff19:39 ff1a:3a ff1b:3b ff1c:3c ff1d:3d ff1e:3e ff20:40 ff21:41 ff22:42 ff23:43 ff24:44 ff25:45 ff26:46 ff27:47 ff28:48 ff29:49 ff2a:4a ff2b:4b ff2c:4c ff2d:4d ff2e:4e ff2f:4f ff30:50 ff31:51 ff32:52 ff33:53 ff34:54 ff35:55 ff36:56 ff37:57 ff38:58 ff39:59 ff3a:5a ff3b:5b ff3c:5c ff3d:5d ff3e:5e ff3f:5f ff40:60 ff41:61 ff42:62 ff43:63 ff44:64 ff45:65 ff46:66 ff47:67 ff48:68 ff49:69 ff4a:6a ff4b:6b ff4c:6c ff4d:6d ff4e:6e ff4f:6f ff50:70 ff51:71 ff52:72 ff53:73 ff54:74 ff55:75 ff56:76 ff57:77 ff58:78 ff59:79 ff5a:7a ff5b:7b ff5c:7c ff5d:7d ff5e:7e 
 
 
 
 1251  (ANSI - Cyrillic)
 
 00c0:41 00c1:41 00c2:41 00c3:41 00c4:41 00c5:41 00c7:43 00c8:45 00c9:45 00ca:45 00cb:45 00cc:49 00cd:49 00ce:49 00cf:49 00d1:4e 00d2:4f 00d3:4f 00d4:4f 00d5:4f 00d6:4f 00d8:4f 00d9:55 00da:55 00db:55 00dc:55 00dd:59 00e0:61 00e1:61 00e2:61 00e3:61 00e4:61 00e5:61 00e7:63 00e8:65 00e9:65 00ea:65 00eb:65 00ec:69 00ed:69 00ee:69 00ef:69 00f1:6e 00f2:6f 00f3:6f 00f4:6f 00f5:6f 00f6:6f 00f8:6f 00f9:75 00fa:75 00fb:75 00fc:75 00fd:79 00ff:79 0100:41 0101:61 0102:41 0103:61 0104:41 0105:61 0106:43 0107:63 0108:43 0109:63 010a:43 010b:63 010c:43 010d:63 010e:44 010f:64 0110:44 0111:64 0112:45 0113:65 0114:45 0115:65 0116:45 0117:65 0118:45 0119:65 011a:45 011b:65 011c:47 011d:67 011e:47 011f:67 0120:47 0121:67 0122:47 0123:67 0124:48 0125:68 0126:48 0127:68 0128:49 0129:69 012a:49 012b:69 012c:49 012d:69 012e:49 012f:69 0130:49 0134:4a 0135:6a 0136:4b 0137:6b 0139:4c 013a:6c 013b:4c 013c:6c 013d:4c 013e:6c 0141:4c 0142:6c 0143:4e 0144:6e 0145:4e 0146:6e 0147:4e 0148:6e 014c:4f 014d:6f 014e:4f 014f:6f 0150:4f 0151:6f 0154:52 0155:72 0156:52 0157:72 0158:52 0159:72 015a:53 015b:73 015c:53 015d:73 015e:53 015f:73 0160:53 0161:73 0162:54 0163:74 0164:54 0165:74 0166:54 0167:74 0168:55 0169:75 016a:55 016b:75 016c:55 016d:75 016e:55 016f:75 0170:55 0171:75 0172:55 0173:75 0174:57 0175:77 0176:59 0177:79 0178:59 0179:5a 017b:5a 017c:7a 017d:5a 017e:7a 0180:62 0197:49 019a:6c 019f:4f 01a0:4f 01a1:6f 01ab:74 01ae:54 01af:55 01b0:75 01cd:41 01ce:61 01cf:49 01d0:69 01d1:4f 01d2:6f 01d3:55 01d4:75 01d5:55 01d6:75 01d7:55 01d8:75 01d9:55 01da:75 01db:55 01dc:75 01de:41 01df:61 01e4:47 01e5:67 01e6:47 01e7:67 01e8:4b 01e9:6b 01ea:4f 01eb:6f 01ec:4f 01ed:6f 01f0:6a 203c:21 2190:3c 2191:5e 2192:3e 2193:76 2194:2d 221a:76 221f:4c 2500:2d 250c:2d 2514:4c 2518:2d 251c:2b 2524:2b 252c:54 2534:2b 253c:2b 2550:3d 2552:2d 2558:4c 2559:4c 255a:4c 255b:2d 255c:2d 255d:2d 2564:54 2565:54 2566:54 256a:2b 256b:2b 256c:2b 2580:2d 2584:2d 2588:2d 2591:2d 2592:2d 2593:2d 25ac:2d 25b2:5e 25ba:3e 25c4:3c 25cb:30 25d9:30 263a:4f 263b:4f 263c:30 2640:2b 2642:3e 266a:64 266b:64 ff01:21 ff02:22 ff03:23 ff04:24 ff05:25 ff06:26 ff07:27 ff08:28 ff09:29 ff0a:2a ff0b:2b ff0c:2c ff0d:2d ff0e:2e ff0f:2f ff10:30 ff11:31 ff12:32 ff13:33 ff14:34 ff15:35 ff16:36 ff17:37 ff18:38 ff19:39 ff1a:3a ff1b:3b ff1c:3c ff1d:3d ff1e:3e ff20:40 ff21:41 ff22:42 ff23:43 ff24:44 ff25:45 ff26:46 ff27:47 ff28:48 ff29:49 ff2a:4a ff2b:4b ff2c:4c ff2d:4d ff2e:4e ff2f:4f ff30:50 ff31:51 ff32:52 ff33:53 ff34:54 ff35:55 ff36:56 ff37:57 ff38:58 ff39:59 ff3a:5a ff3b:5b ff3c:5c ff3d:5d ff3e:5e ff3f:5f ff40:60 ff41:61 ff42:62 ff43:63 ff44:64 ff45:65 ff46:66 ff47:67 ff48:68 ff49:69 ff4a:6a ff4b:6b ff4c:6c ff4d:6d ff4e:6e ff4f:6f ff50:70 ff51:71 ff52:72 ff53:73 ff54:74 ff55:75 ff56:76 ff57:77 ff58:78 ff59:79 ff5a:7a ff5b:7b ff5c:7c ff5d:7d ff5e:7e 
 
 
 
 1252  (ANSI - Latin I)
 
 0100:41 0101:61 0102:41 0103:61 0104:41 0105:61 0106:43 0107:63 0108:43 0109:63 010a:43 010b:63 010c:43 010d:63 010e:44 010f:64 0111:64 0112:45 0113:65 0114:45 0115:65 0116:45 0117:65 0118:45 0119:65 011a:45 011b:65 011c:47 011d:67 011e:47 011f:67 0120:47 0121:67 0122:47 0123:67 0124:48 0125:68 0126:48 0127:68 0128:49 0129:69 012a:49 012b:69 012c:49 012d:69 012e:49 012f:69 0130:49 0131:69 0134:4a 0135:6a 0136:4b 0137:6b 0139:4c 013a:6c 013b:4c 013c:6c 013d:4c 013e:6c 0141:4c 0142:6c 0143:4e 0144:6e 0145:4e 0146:6e 0147:4e 0148:6e 014c:4f 014d:6f 014e:4f 014f:6f 0150:4f 0151:6f 0154:52 0155:72 0156:52 0157:72 0158:52 0159:72 015a:53 015b:73 015c:53 015d:73 015e:53 015f:73 0162:54 0163:74 0164:54 0165:74 0166:54 0167:74 0168:55 0169:75 016a:55 016b:75 016c:55 016d:75 016e:55 016f:75 0170:55 0171:75 0172:55 0173:75 0174:57 0175:77 0176:59 0177:79 0179:5a 017b:5a 017c:7a 0180:62 0197:49 019a:6c 019f:4f 01a0:4f 01a1:6f 01ab:74 01ae:54 01af:55 01b0:75 01b6:7a 01c0:7c 01c3:21 01cd:41 01ce:61 01cf:49 01d0:69 01d1:4f 01d2:6f 01d3:55 01d4:75 01d5:55 01d6:75 01d7:55 01d8:75 01d9:55 01da:75 01db:55 01dc:75 01de:41 01df:61 01e4:47 01e5:67 01e6:47 01e7:67 01e8:4b 01e9:6b 01ea:4f 01eb:6f 01ec:4f 01ed:6f 01f0:6a 0261:67 02b9:27 02ba:22 02bc:27 02c4:5e 02c8:27 02cb:60 02cd:5f 0300:60 0302:5e 0303:7e 030e:22 0331:5f 0332:5f 037e:3b 0393:47 0398:54 03a3:53 03a6:46 03a9:4f 03b1:61 03b4:64 03b5:65 03c0:70 03c3:73 03c4:74 03c6:66 04bb:68 0589:3a 066a:25 2000:20 2001:20 2002:20 2003:20 2004:20 2005:20 2006:20 2010:2d 2011:2d 2017:3d 2032:27 2035:60 2044:2f 2074:34 2075:35 2076:36 2077:37 2078:38 207f:6e 2080:30 2081:31 2082:32 2083:33 2084:34 2085:35 2086:36 2087:37 2088:38 2089:39 20a7:50 2102:43 2107:45 210a:67 210b:48 210c:48 210d:48 210e:68 2110:49 2111:49 2112:4c 2113:6c 2115:4e 2118:50 2119:50 211a:51 211b:52 211c:52 211d:52 2124:5a 2128:5a 212a:4b 212c:42 212d:43 212e:65 212f:65 2130:45 2131:46 2133:4d 2134:6f 2212:2d 2215:2f 2216:5c 2217:2a 221a:76 221e:38 2223:7c 2229:6e 2236:3a 223c:7e 2261:3d 2264:3d 2265:3d 2303:5e 2320:28 2321:29 2329:3c 232a:3e 2500:2d 250c:2b 2510:2b 2514:2b 2518:2b 251c:2b 252c:2d 2534:2d 253c:2b 2550:2d 2552:2b 2553:2b 2554:2b 2555:2b 2556:2b 2557:2b 2558:2b 2559:2b 255a:2b 255b:2b 255c:2b 255d:2b 2564:2d 2565:2d 2566:2d 2567:2d 2568:2d 2569:2d 256a:2b 256b:2b 256c:2b 2584:5f 2758:7c 3000:20 3008:3c 3009:3e 301a:5b 301b:5d ff01:21 ff02:22 ff03:23 ff04:24 ff05:25 ff06:26 ff07:27 ff08:28 ff09:29 ff0a:2a ff0b:2b ff0c:2c ff0d:2d ff0e:2e ff0f:2f ff10:30 ff11:31 ff12:32 ff13:33 ff14:34 ff15:35 ff16:36 ff17:37 ff18:38 ff19:39 ff1a:3a ff1b:3b ff1c:3c ff1d:3d ff1e:3e ff20:40 ff21:41 ff22:42 ff23:43 ff24:44 ff25:45 ff26:46 ff27:47 ff28:48 ff29:49 ff2a:4a ff2b:4b ff2c:4c ff2d:4d ff2e:4e ff2f:4f ff30:50 ff31:51 ff32:52 ff33:53 ff34:54 ff35:55 ff36:56 ff37:57 ff38:58 ff39:59 ff3a:5a ff3b:5b ff3c:5c ff3d:5d ff3e:5e ff3f:5f ff40:60 ff41:61 ff42:62 ff43:63 ff44:64 ff45:65 ff46:66 ff47:67 ff48:68 ff49:69 ff4a:6a ff4b:6b ff4c:6c ff4d:6d ff4e:6e ff4f:6f ff50:70 ff51:71 ff52:72 ff53:73 ff54:74 ff55:75 ff56:76 ff57:77 ff58:78 ff59:79 ff5a:7a ff5b:7b ff5c:7c ff5d:7d ff5e:7e 
 
 
 
 1253  (ANSI - Greek)
 
 00b4:2f 00c0:41 00c1:41 00c2:41 00c3:41 00c4:41 00c5:41 00c7:43 00c8:45 00c9:45 00ca:45 00cb:45 00cc:49 00cd:49 00ce:49 00cf:49 00d1:4e 00d2:4f 00d3:4f 00d4:4f 00d5:4f 00d6:4f 00d8:4f 00d9:55 00da:55 00db:55 00dc:55 00dd:59 00e0:61 00e1:61 00e2:61 00e3:61 00e4:61 00e5:61 00e7:63 00e8:65 00e9:65 00ea:65 00eb:65 00ec:69 00ed:69 00ee:69 00ef:69 00f1:6e 00f2:6f 00f3:6f 00f4:6f 00f5:6f 00f6:6f 00f8:6f 00f9:75 00fa:75 00fb:75 00fc:75 00fd:79 00ff:79 0100:41 0101:61 0102:41 0103:61 0104:41 0105:61 0106:43 0107:63 0108:43 0109:63 010a:43 010b:63 010c:43 010d:63 010e:44 010f:64 0110:44 0111:64 0112:45 0113:65 0114:45 0115:65 0116:45 0117:65 0118:45 0119:65 011a:45 011b:65 011c:47 011d:67 011e:47 011f:67 0120:47 0121:67 0122:47 0123:67 0124:48 0125:68 0126:48 0127:68 0128:49 0129:69 012a:49 012b:69 012c:49 012d:69 012e:49 012f:69 0130:49 0134:4a 0135:6a 0136:4b 0137:6b 0139:4c 013a:6c 013b:4c 013c:6c 013d:4c 013e:6c 0141:4c 0142:6c 0143:4e 0144:6e 0145:4e 0146:6e 0147:4e 0148:6e 014c:4f 014d:6f 014e:4f 014f:6f 0150:4f 0151:6f 0154:52 0155:72 0156:52 0157:72 0158:52 0159:72 015a:53 015b:73 015c:53 015d:73 015e:53 015f:73 0160:53 0161:73 0162:54 0163:74 0164:54 0165:74 0166:54 0167:74 0168:55 0169:75 016a:55 016b:75 016c:55 016d:75 016e:55 016f:75 0170:55 0171:75 0172:55 0173:75 0174:57 0175:77 0176:59 0177:79 0178:59 0179:5a 017b:5a 017c:7a 017d:5a 017e:7a 0180:62 0197:49 019a:6c 019f:4f 01a0:4f 01a1:6f 01ab:74 01ae:54 01af:55 01b0:75 01cd:41 01ce:61 01cf:49 01d0:69 01d1:4f 01d2:6f 01d3:55 01d4:75 01d5:55 01d6:75 01d7:55 01d8:75 01d9:55 01da:75 01db:55 01dc:75 01de:41 01df:61 01e4:47 01e5:67 01e6:47 01e7:67 01e8:4b 01e9:6b 01ea:4f 01eb:6f 01ec:4f 01ed:6f 01f0:6a 037e:3b 203c:21 2190:3c 2191:5e 2192:3e 2193:76 2194:2d 221f:4c 2500:2d 250c:2d 2514:4c 2518:2d 251c:2b 2524:2b 252c:54 2534:2b 253c:2b 2550:3d 2554:2d 255a:4c 255d:2d 2566:54 256c:2b 2580:2d 2584:2d 2588:2d 2591:2d 2592:2d 2593:2d 25ac:2d 25b2:5e 25ba:3e 25c4:3c 25cb:30 25d9:30 263a:4f 263b:4f 263c:30 2640:2b 2642:3e 266a:64 266b:64 ff01:21 ff02:22 ff03:23 ff04:24 ff05:25 ff06:26 ff07:27 ff08:28 ff09:29 ff0a:2a ff0b:2b ff0c:2c ff0d:2d ff0e:2e ff0f:2f ff10:30 ff11:31 ff12:32 ff13:33 ff14:34 ff15:35 ff16:36 ff17:37 ff18:38 ff19:39 ff1a:3a ff1b:3b ff1c:3c ff1d:3d ff1e:3e ff20:40 ff21:41 ff22:42 ff23:43 ff24:44 ff25:45 ff26:46 ff27:47 ff28:48 ff29:49 ff2a:4a ff2b:4b ff2c:4c ff2d:4d ff2e:4e ff2f:4f ff30:50 ff31:51 ff32:52 ff33:53 ff34:54 ff35:55 ff36:56 ff37:57 ff38:58 ff39:59 ff3a:5a ff3b:5b ff3c:5c ff3d:5d ff3e:5e ff3f:5f ff40:60 ff41:61 ff42:62 ff43:63 ff44:64 ff45:65 ff46:66 ff47:67 ff48:68 ff49:69 ff4a:6a ff4b:6b ff4c:6c ff4d:6d ff4e:6e ff4f:6f ff50:70 ff51:71 ff52:72 ff53:73 ff54:74 ff55:75 ff56:76 ff57:77 ff58:78 ff59:79 ff5a:7a ff5b:7b ff5c:7c ff5d:7d ff5e:7e" >> unicode.mapping
 
sed -ie 's/^\s*SecRuleEngine DetectionOnly/SecRuleEngine On/' /usr/local/etc/modsecurity/modsecurity.conf

echo "Configuring Server Stack..."

sysrc nginx_enable="YES"

sysrc php_fpm_enable="YES"

sysrc varnishd_enable=YES

sysrc varnishd_listen=":80"

sysrc varnishd_backend="localhost:8080"

sysrc varnishd_storage="malloc,512M"

sysrc varnishd_admin=":8081"

mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf_bk

mv /usr/local/etc/nginx/mime.types /usr/local/etc/nginx/mime.types_bk

mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf_bk

cd /usr/local/etc/php-fpm.d/ && fetch https://github.com/Wamphyre/BeastNgine/blob/master/www.conf

cd /usr/local/etc/nginx/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/nginx.conf

cd /usr/local/etc/nginx/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/mime.types

mkdir conf.d

touch /usr/local/etc/nginx/conf.d/default_vhost.conf && cd /usr/local/etc/nginx/conf.d/

DOMINIO=$(hostname)

echo "

server {
listen 8080;
listen [::]:8080;

server_name $DOMINIO;

root /usr/local/www/public_html;
index index.php index.html;
    
    resolver                   1.1.1.1;
    # allow POSTs to static pages
    error_page                 405    =200 \$uri;
    access_log                 /var/log/nginx/$DOMINIO-access.log;
    error_log                  /var/log/nginx/$DOMINIO-error.log;

        location / {
                # This is cool because no php is touched for static content.
                # include the "\$is_args\$args" so non-default permalinks doesn't break when using query string
                try_files \$uri \$uri/ /index.php\$is_args\$args;
        }
	
	 # deny access to xmlrpc.php which allows brute-forcing at a higher rates
        # than wp-login.php; this may break some functionality, like WordPress
        # iOS/Android app posting 
        location ~* /xmlrpc\.php {
            deny                        all;
        }

# Media: images, icons, video, audio, HTC
location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)\$ {
	expires 1M;
	access_log off;
	add_header Cache-Control "public";
}

# CSS and Javascript
location ~* \.(?:css|js)\$ {
	expires 1y;
	access_log off;
	add_header Cache-Control "public";
}

location = ^/favicon.ico {
    access_log off;
    log_not_found off;
}

# robots noise...
location = ^/robots.txt {
    log_not_found off;
    access_log off;
    allow all;
}

# block access to hidden files (.htaccess per example)
location ~ /\. { access_log off; log_not_found off; deny all; }

     location ~ [^/]\.php(/|$) {
        root	/usr/local/www/public_html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME \$request_filename;    
        include        fastcgi_params;
        	}
}
" >> default_vhost.conf

service nginx start

service varnishd start

mv /usr/local/etc/php.ini-production /usr/local/etc/php.ini-production_bk

cd /usr/local/etc/ && fetch https://github.com/Wamphyre/BeastNgine/blob/master/php.ini

mkdir /usr/local/www/public_html/

cd /usr/local/www/public_html/

chown -R www:www /usr/local/www/public_html/

echo ""

sysrc mysql_enable="YES"

sysrc mysql_args="--bind-address=127.0.0.1"

service mysql-server start

sleep 5

/usr/local/bin/mysql_secure_installation

echo ; read -p "Want to install phpmyadmin?: (yes/no) " PHPMYADMIN;

if [ "$PHPMYADMIN" = "yes" ] 

then cd /usr/local/www/public_html/;

pkg install -y phpMyAdmin-php80

ln -s /usr/local/www/phpMyAdmin/ /usr/local/www/public_html/phpmyadmin

service nginx restart

service php-fpm restart

cd;

else echo "Ignoring phpmyadmin installation" 

fi

echo "Aplying hardening and system tuning"

echo ""

mv /etc/sysctl.conf /etc/sysctl.conf.bk
echo 'vfs.usermount=1' >> /etc/sysctl.conf
echo 'vfs.vmiodirenable=0' >> /etc/sysctl.conf
echo 'vfs.read_max=4' >> /etc/sysctl.conf
echo 'kern.ipc.shmmax=67108864' >> /etc/sysctl.conf
echo 'kern.ipc.shmall=32768' >> /etc/sysctl.conf
echo 'kern.ipc.somaxconn=256' >> /etc/sysctl.conf
echo 'kern.ipc.shm_use_phys=1' >> /etc/sysctl.conf
echo 'kern.ipc.somaxconn=32' >> /etc/sysctl.conf
echo 'kern.maxvnodes=60000' >> /etc/sysctl.conf
echo 'kern.coredump=0' >> /etc/sysctl.conf
echo 'kern.sched.preempt_thresh=224' >> /etc/sysctl.conf
echo 'kern.sched.slice=3' >> /etc/sysctl.conf
echo 'hw.snd.feeder_rate_quality=3' >> /etc/sysctl.conf
echo 'hw.snd.maxautovchans=32' >> /etc/sysctl.conf
echo 'vfs.lorunningspace=1048576' >> /etc/sysctl.conf
echo 'vfs.hirunningspace=5242880' >> /etc/sysctl.conf
echo 'kern.ipc.shm_allow_removed=1' >> /etc/sysctl.conf
echo 'hw.snd.vpc_autoreset=0' >> /boot/loader.conf
echo 'hw.syscons.bell=0' >> /boot/loader.conf
echo 'hw.usb.no_pf=1' >> /boot/loader.conf
echo 'hw.usb.no_boot_wait=0' >> /boot/loader.conf
echo 'hw.usb.no_shutdown_wait=1' >> /boot/loader.conf
echo 'hw.psm.synaptics_support=1' >> /boot/loader.conf
echo 'kern.maxfiles="25000"' >> /boot/loader.conf
echo 'kern.maxusers=16' >> /boot/loader.conf
echo 'kern.cam.scsi_delay=10000' >> /boot/loader.conf

sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive"
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc sendmail_enable="YES"
sysrc dumpdev="NO"
sysrc sshguard_enable="YES"

echo 'kern.elf64.nxstack=1' >> /etc/sysctl.conf
echo 'security.bsd.map_at_zero=0' >> /etc/sysctl.conf
echo 'security.bsd.see_other_uids=0' >> /etc/sysctl.conf
echo 'security.bsd.see_other_gids=0' >> /etc/sysctl.conf
echo 'security.bsd.unprivileged_read_msgbuf=0' >> /etc/sysctl.conf
echo 'security.bsd.unprivileged_proc_debug=0' >> /etc/sysctl.conf
echo 'kern.randompid=9800' >> /etc/sysctl.conf
echo 'security.bsd.stack_guard_page=1' >> /etc/sysctl.conf
echo 'net.inet.udp.blackhole=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.blackhole=2' >> /etc/sysctl.conf
echo 'net.inet.ip.random_id=1' >> /etc/sysctl.conf

echo ""

echo "Optimizing FreeBSD network stack settings"

echo ""

echo 'kern.ipc.soacceptqueue=1024' >> /etc/sysctl.conf
echo 'kern.ipc.maxsockbuf=8388608' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendspace=262144' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvspace=262144' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendbuf_max=16777216' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvbuf_max=16777216' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendbuf_inc=32768' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvbuf_inc=65536' >> /etc/sysctl.conf
echo 'net.inet.raw.maxdgram=16384' >> /etc/sysctl.conf
echo 'net.inet.raw.recvspace=16384' >> /etc/sysctl.conf
echo 'net.inet.tcp.abc_l_var=44' >> /etc/sysctl.conf
echo 'net.inet.tcp.initcwnd_segments=44' >> /etc/sysctl.conf
echo 'net.inet.tcp.mssdflt=1448' >> /etc/sysctl.conf
echo 'net.inet.tcp.minmss=524' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.algorithm=htcp' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.htcp.adaptive_backoff=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.htcp.rtt_scaling=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.rfc6675_pipe=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.syncookies=0' >> /etc/sysctl.conf
echo 'net.inet.tcp.nolocaltimewait=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.tso=0' >> /etc/sysctl.conf
echo 'net.inet.ip.intr_queue_maxlen=2048' >> /etc/sysctl.conf
echo 'net.route.netisr_maxqlen=2048' >> /etc/sysctl.conf
echo 'dev.igb.0.fc=0' >> /etc/sysctl.conf
echo 'dev.igb.1.fc=0' >> /etc/sysctl.conf
echo 'aio_load="yes"' >> /boot/loader.conf
echo 'cc_htcp_load="YES"' >> /boot/loader.conf
echo 'accf_http_load="YES"' >> /boot/loader.conf
echo 'accf_data_load="YES"' >> /boot/loader.conf
echo 'accf_dns_load="YES"' >> /boot/loader.conf
echo 'net.inet.tcp.hostcache.cachelimit="0"' >> /boot/loader.conf
echo 'net.link.ifqmaxlen="2048"' >> /boot/loader.conf
echo 'net.inet.tcp.soreceive_stream="1"' >> /boot/loader.conf
echo 'hw.igb.rx_process_limit="-1"' >> /boot/loader.conf
echo 'ahci_load="YES"' >> /boot/loader.conf
echo 'coretemp_load="YES"' >> /boot/loader.conf
echo 'tmpfs_load="YES"' >> /boot/loader.conf
echo 'if_igb_load="YES"' >> /boot/loader.conf

echo ""

echo "Updating CPU microcode"

echo ""

pkg install -y devcpu-data

sysrc microcode_update_enable="YES"

service microcode_update start

echo ""

echo "Microcode updated"

echo ""

echo "Setting up PF firewall"

echo ""

touch /etc/pf.conf

echo "Showing network interfaces"

echo ""

ifconfig | grep :

echo ""

echo ; read -p "Please, select a network interface: " INTERFAZ;

echo ""

echo '# the external network interface to the internet
ext_if="'$INTERFAZ'"
# port on which sshd is running
ssh_port = "22"
# allowed inbound ports (services hosted by this machine)
inbound_tcp_services = "{80, 443, 21, 25," $ssh_port " }"
inbound_udp_services = "{80, 8080, 443}"
# politely send TCP RST for blocked packets. The alternative is
# "set block-policy drop", which will cause clients to wait for a timeout
# before giving up.
set block-policy return
# log only on the external interface
set loginterface $ext_if
# skip all filtering on localhost
set skip on lo
# reassemble all fragmented packets before filtering them
scrub in on $ext_if all fragment reassemble
# block forged client IPs (such as private addresses from WAN interface)
antispoof for $ext_if
# default behavior: block all traffic
block all
# allow all icmp traffic (like ping)
pass quick on $ext_if proto icmp
pass quick on $ext_if proto icmp6
# allow incoming traffic to services hosted by this machine
pass in quick on $ext_if proto tcp to port $inbound_tcp_services
pass in quick on $ext_if proto udp to port $inbound_udp_services
# allow all outgoing traffic
pass out quick on $ext_if
table <sshguard> persist
block in quick on $ext_if from <sshguard>' >> /etc/pf.conf

IP=$(curl ifconfig.me)

echo "pass in on \$ext_if proto tcp from any to $IP port 21 flags S/SA synproxy state
pass in on \$ext_if proto tcp from any to $IP port > 49151 keep state
# keep stats of outgoing connections
pass out keep state" >> /etc/pf.conf

echo ""

kldload pf
service sshguard start

echo "Firewall rules configured for $INTERFAZ"

echo ""

echo "Cleaning system..."

echo ""

pkg clean -y && pkg autoremove -y

echo ""

echo "Installation finished, please restart your system"
