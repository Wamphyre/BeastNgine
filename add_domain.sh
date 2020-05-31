#!/bin/bash

clear

echo "Vamos a crear un nuevo VHOST"

echo ""

sleep 1

echo ; read -p "Dime dominio a añadir: " DOMINIO

cd /usr/local/etc/nginx/conf.d && touch $DOMINIO.conf

mkdir /usr/local/www/public_html/$DOMINIO

ln -s /usr/local/www/phpMyAdmin/ /usr/local/www/public_html/$DOMINIO/phpmyadmin

chown -R www:www /usr/local/www/public_html/$DOMINIO

echo ""

echo "

server {
listen 8080;
listen [::]:8080;

server_name $DOMINIO;

root /usr/local/www/public_html/$DOMINIO;
index index.php index.html;

   #Gzip settings
    gzip             on;
    gzip_comp_level  5;
    gzip_min_length  256;
    gzip_proxied     expired no-cache no-store private auth;
    gzip_types       text/plain application/x-javascript text/xml text/css application/xml;
    gzip_vary on;

    # Static resources
    location ~* \.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)\$ {
        expires max;
        log_not_found off;
        access_log off;
    }

   #Security headers
   add_header X-Frame-Options \"SAMEORIGIN\" always;
   add_header X-XSS-Protection \"1; mode=block\" always;
   add_header X-Content-Type-Options \"nosniff\" always;
   add_header Referrer-Policy \"no-referrer-when-downgrade\" always;
   add_header Content-Security-Policy \"default-src * data: 'unsafe-eval' 'unsafe-inline'\" always;
    
    # allow POSTs to static pages
    error_page                 405    =200 \$uri;
    access_log                 /var/log/nginx/$DOMINIO-access.log;
    error_log                  /var/log/nginx/$DOMINIO-error.log;
            
        if (\$http_referer ~* (babes|click|diamond|forsale|girl|jewelry|love|nudit|organic|poker|porn|poweroversoftware|sex|teen|video|webcam|zippo) ) {
       return 444;
      }
        
       if (\$http_user_agent ~* (360Spider|80legs.com|Abonti|AcoonBot|Acunetix|adbeat_bot|AddThis.com|adidxbot|ADmantX|AhrefsBot|AngloINFO|Antelope|Applebot|BaiduSpider|BeetleBot|billigerbot|binlar|bitlybot|BlackWidow|BLP_bbot|BoardReader|Bolt\ 0|BOT\ for\ JCE|Bot\ mailto\:craftbot@yahoo\.com|casper|CazoodleBot|CCBot|checkprivacy|ChinaClaw|chromeframe|Clerkbot|Cliqzbot|clshttp|CommonCrawler|comodo|CPython|crawler4j|Crawlera|CRAZYWEBCRAWLER|Curious|Curl|Custo|CWS_proxy|Default\ Browser\ 0|diavol|DigExt|Digincore|DIIbot|discobot|DISCo|DoCoMo|DotBot|Download\ Demon|DTS.Agent|EasouSpider|eCatch|ecxi|EirGrabber|Elmer|EmailCollector|EmailSiphon|EmailWolf|Exabot|ExaleadCloudView|ExpertSearchSpider|ExpertSearch|Express\ WebPictures|ExtractorPro|extract|EyeNetIE|Ezooms|F2S|FastSeek|feedfinder|FeedlyBot|FHscan|finbot|Flamingo_SearchEngine|FlappyBot|FlashGet|flicky|Flipboard|g00g1e|Genieo|genieo|GetRight|GetWeb\!|GigablastOpenSource|GozaikBot|Go\!Zilla|Go\-Ahead\-Got\-It|GrabNet|grab|Grafula|GrapeshotCrawler|GTB5|GT\:\:WWW|Guzzle|harvest|heritrix|HMView|HomePageBot|HTTP\:\:Lite|HTTrack|HubSpot|ia_archiver|icarus6|IDBot|id\-search|IlseBot|Image\ Stripper|Image\ Sucker|Indigonet|Indy\ Library|integromedb|InterGET|InternetSeer\.com|Internet\ Ninja|IRLbot|ISC\ Systems\ iRc\ Search\ 2\.1|jakarta|Java|JetCar|JobdiggerSpider|JOC\ Web\ Spider|Jooblebot|kanagawa|KINGSpider|kmccrew|larbin|LeechFTP|libwww|Lingewoud|LinkChecker|linkdexbot|LinksCrawler|LinksManager\.com_bot|linkwalker|LinqiaRSSBot|LivelapBot|ltx71|LubbersBot|lwp\-trivial|Mail.RU_Bot|masscan|Mass\ Downloader|maverick|Maxthon$|Mediatoolkitbot|MegaIndex|MegaIndex|megaindex|MFC_Tear_Sample|Microsoft\ URL\ Control|microsoft\.url|MIDown\ tool|miner|Missigua\ Locator|Mister\ PiX|mj12bot|Mozilla.*Indy|Mozilla.*NEWT|MSFrontPage|msnbot|Navroad|NearSite|NetAnts|netEstate|NetSpider|NetZIP|Net\ Vampire|NextGenSearchBot|nutch|Octopus|Offline\ Explorer|Offline\ Navigator|OpenindexSpider|OpenWebSpider|OrangeBot|Owlin|PageGrabber|PagesInventory|panopta|panscient\.com|Papa\ Foto|pavuk|pcBrowser|PECL\:\:HTTP|PeoplePal|Photon|PHPCrawl|planetwork|PleaseCrawl|PNAMAIN.EXE|PodcastPartyBot|prijsbest|proximic|psbot|purebot|pycurl|QuerySeekerSpider|R6_CommentReader|R6_FeedFetcher|RealDownload|ReGet|Riddler|Rippers\ 0|rogerbot|RSSingBot|rv\:1.9.1|RyzeCrawler|SafeSearch|SBIder|Scrapy|Scrapy|Screaming|SeaMonkey$|search.goo.ne.jp|SearchmetricsBot|search_robot|SemrushBot|Semrush|SentiBot|SEOkicks|SeznamBot|ShowyouBot|SightupBot|SISTRIX|sitecheck\.internetseer\.com|siteexplorer.info|SiteSnagger|skygrid|Slackbot|Slurp|SmartDownload|Snoopy|Sogou|Sosospider|spaumbot|Steeler|sucker|SuperBot|Superfeedr|SuperHTTP|SurdotlyBot|Surfbot|tAkeOut|Teleport\ Pro|TinEye-bot|TinEye|Toata\ dragostea\ mea\ pentru\ diavola|Toplistbot|trendictionbot|TurnitinBot|turnit|Twitterbot|URI\:\:Fetch|urllib|Vagabondo|Vagabondo|vikspider|VoidEYE|VoilaBot|WBSearchBot|webalta|WebAuto|WebBandit|WebCollage|WebCopier|WebFetch|WebGo\ IS|WebLeacher|WebReaper|WebSauger|Website\ eXtractor|Website\ Quester|WebStripper|WebWhacker|WebZIP|Web\ Image\ Collector|Web\ Sucker|Wells\ Search\ II|WEP\ Search|WeSEE|Wget|Widow|WinInet|woobot|woopingbot|worldwebheritage.org|Wotbox|WPScan|WWWOFFLE|WWW\-Mechanize|Xaldon\ WebSpider|XoviBot|yacybot|Yahoo|YandexBot|Yandex|YisouSpider|zermelo|Zeus|zh-CN|ZmEu|ZumBot|ZyBorg) ) {
    return 444;
      }

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

        location ~* /wp-config\.php {
            deny                        all;
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

        # Deny public access to wp-config.php
        location ~* wp-config.php {
        deny all;
        }

        location ~ [^/]\.php(/|$) {
        root	/usr/local/www/public_html/$DOMINIO;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME \$request_filename;    
        include        fastcgi_params;
        	}		
}
" >> $DOMINIO.conf

echo "VHOST para $DOMINIO creado correctamente"

echo ""

echo "Reiniciando NGINX"

sleep 2

service nginx restart

service php-fpm restart

echo ""

echo "Completado"
