CREATE TABLE `clockwork_raven_evaluations` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `desc` text,
  `payment` int(11) NOT NULL DEFAULT '30',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `keywords` varchar(511) DEFAULT NULL,
  `mturk_hit_type` varchar(255) DEFAULT NULL,
  `duration` int(11) NOT NULL DEFAULT '3600',
  `lifetime` int(11) NOT NULL DEFAULT '604800',
  `auto_approve` int(11) NOT NULL DEFAULT '86400',
  `status` int(1) NOT NULL DEFAULT '0',
  `mturk_qualification` varchar(255) NOT NULL DEFAULT 'trusted',
  `title` varchar(255) NOT NULL DEFAULT '',
  `note` varchar(255) DEFAULT NULL,
  `prod` int(11) NOT NULL DEFAULT '1',
  `template` text,
  `metadata` text,
  `user_id` int(11) NOT NULL,
  `job_id` int(10) unsigned DEFAULT NULL,
  `num_judges_per_task` int(11) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_evaluations_jobs` (`job_id`),
  CONSTRAINT `fk_evaluations_jobs` FOREIGN KEY (`job_id`) REFERENCES `clockwork_raven_jobs` (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_fr_question_responses` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `fr_question_id` int(11) unsigned NOT NULL,
  `task_response_id` int(11) unsigned NOT NULL,
  `response` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fr_question_id` (`fr_question_id`),
  KEY `task_response_id` (`task_response_id`),
  CONSTRAINT `clockwork_raven_fr_question_responses_ibfk_1` FOREIGN KEY (`fr_question_id`) REFERENCES `clockwork_raven_fr_questions` (`id`),
  CONSTRAINT `clockwork_raven_fr_question_responses_ibfk_2` FOREIGN KEY (`task_response_id`) REFERENCES `clockwork_raven_task_responses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_fr_questions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `evaluation_id` int(11) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `order` int(11) DEFAULT NULL,
  `required` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `evaluation_id` (`evaluation_id`),
  CONSTRAINT `clockwork_raven_fr_questions_ibfk_1` FOREIGN KEY (`evaluation_id`) REFERENCES `clockwork_raven_evaluations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_jobs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `complete_url` varchar(255) NOT NULL DEFAULT '',
  `back_url` varchar(255) NOT NULL DEFAULT '',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `resque_job` varchar(255) DEFAULT NULL,
  `processor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_m_turk_users` (
  `id` varchar(255) NOT NULL DEFAULT '',
  `trusted` tinyint(1) NOT NULL DEFAULT '0',
  `banned` tinyint(1) NOT NULL DEFAULT '0',
  `prod` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_mc_question_options` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `mc_question_id` int(11) unsigned DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  `order` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `mc_question_id` (`mc_question_id`),
  CONSTRAINT `clockwork_raven_mc_question_options_ibfk_1` FOREIGN KEY (`mc_question_id`) REFERENCES `clockwork_raven_mc_questions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_mc_question_responses` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `mc_question_option_id` int(11) unsigned DEFAULT NULL,
  `task_response_id` int(11) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `mc_question_option_id` (`mc_question_option_id`),
  KEY `task_response_id` (`task_response_id`),
  CONSTRAINT `clockwork_raven_mc_question_responses_ibfk_1` FOREIGN KEY (`mc_question_option_id`) REFERENCES `clockwork_raven_mc_question_options` (`id`),
  CONSTRAINT `clockwork_raven_mc_question_responses_ibfk_2` FOREIGN KEY (`task_response_id`) REFERENCES `clockwork_raven_task_responses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_mc_questions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `evaluation_id` int(11) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `metadata` tinyint(1) NOT NULL DEFAULT '0',
  `order` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `evaluation_id` (`evaluation_id`),
  CONSTRAINT `clockwork_raven_mc_questions_ibfk_1` FOREIGN KEY (`evaluation_id`) REFERENCES `clockwork_raven_evaluations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `clockwork_raven_unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `clockwork_raven_task_responses` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) unsigned DEFAULT NULL,
  `m_turk_user_id` varchar(255) NOT NULL DEFAULT '',
  `work_duration` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `mturk_assignment` varchar(255) DEFAULT NULL,
  `approved` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `task_id` (`task_id`),
  CONSTRAINT `clockwork_raven_task_responses_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `clockwork_raven_tasks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_tasks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `evaluation_id` int(11) unsigned DEFAULT NULL,
  `data` text,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `mturk_hit` varchar(255) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `evaluation_id` (`evaluation_id`),
  CONSTRAINT `clockwork_raven_tasks_ibfk_1` FOREIGN KEY (`evaluation_id`) REFERENCES `clockwork_raven_evaluations` (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE `clockwork_raven_users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `username` varchar(128) NOT NULL DEFAULT '',
  `key` varchar(24) NOT NULL DEFAULT '',
  `email` varchar(128) DEFAULT NULL,
  `privileged` tinyint(1) DEFAULT NULL,
  `name` varchar(256) DEFAULT NULL,
  `password_digest` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20120730234713');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20120806175031');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20120806234641');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20120807222553');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20120810203402');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20121020214517');

INSERT INTO clockwork_raven_schema_migrations (version) VALUES ('20121121095458');