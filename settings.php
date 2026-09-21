<?php

return [
    'site.title' => '__AGENDAV_TITLE__',
    'site.footer' => '__AGENDAV_FOOTER__',

    'db.options' => [
        'path' => '/var/agendav/db.sqlite',
        'driver' => 'pdo_sqlite',
    ],
    'session.handler' => 'native',

    'csrf.secret' => '__AGENDAV_CSRF_SECRET__',

    'log.path' => '__AGENDAV_LOG_DIR__',

    'caldav.baseurl' => '__AGENDAV_CALDAV_SERVER__',
    'caldav.authmethod' => 'basic',
    'caldav.publicurls' => true,
    'caldav.baseurl.public' => '__AGENDAV_CALDAV_PUBLIC_URL__',

    'defaults.timezone' => '__AGENDAV_TIMEZONE__',
    'defaults.language' => '__AGENDAV_LANG__',
    'defaults.time_format' => '24',
    'defaults.date_format' => 'ymd',
    'defaults.weekstart' => __AGENDAV_WEEKSTART__,
];
