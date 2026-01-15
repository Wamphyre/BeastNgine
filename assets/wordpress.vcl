vcl 4.0;

# Definición del backend
backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
    .max_connections = 800;
}

# Permitir purga solo desde IPs específicas
acl purge {
    "localhost";
    "127.0.0.1";
}

sub vcl_recv {
    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405, "This IP is not allowed to send PURGE requests."));
        }
        return (purge);
    }

    if (req.http.Authorization || req.method == "POST") {
        return (pass);
    }

    if (req.url ~ "^/wp-admin/|^/wp-login.php") {
        return (pass);
    }

    if (req.url ~ "^/feed|/wp-(json|cron)") {
        return (pass);
    }

    if (req.url ~ "/(cart|my-account|checkout|addons|/?add-to-cart=)") {
        return (pass);
    }

    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

    if (req.http.cookie ~ "^ *$") {
        unset req.http.cookie;
    }

    if (req.url ~ "\.(css|js|png|gif|jp(e)?g|swf|ico)$") {
        unset req.http.cookie;
    }

    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            unset req.http.Accept-Encoding;
        } elseif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elseif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    if (req.http.Cookie ~ "wordpress_logged_in_|wp-postpass_|wordpress_sec_|wordpress_[a-zA-Z0-9]+") {
        return (pass);
    }

    return (hash);
}

sub vcl_pipe {
    return (pipe);
}

sub vcl_pass {
    return (fetch);
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    if (req.http.Accept-Encoding) {
        hash_data(req.http.Accept-Encoding);
    }

    return (lookup);
}

sub vcl_backend_response {
    unset beresp.http.Server;
    unset beresp.http.X-Powered-By;

    if (bereq.url ~ "\.(css|js|png|gif|jp(e?)g|swf|ico)$") {
        unset beresp.http.cookie;
    }

    if (beresp.http.Set-Cookie && bereq.url !~ "^/wp-(login|admin)") {
        unset beresp.http.Set-Cookie;
    }

    if (bereq.method == "POST" || bereq.http.Authorization) {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }

    if (bereq.url ~ "\?s=") {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }

    if (beresp.status != 200) {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }

    set beresp.ttl = 24h;
    set beresp.grace = 30s;

    return (deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    unset resp.http.X-Powered-By;
    unset resp.http.Server;
    unset resp.http.Via;
    unset resp.http.X-Varnish;

    return (deliver);
}

sub vcl_init {
    return (ok);
}

sub vcl_fini {
    return (ok);
}
