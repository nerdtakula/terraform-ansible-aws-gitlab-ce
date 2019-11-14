# terraform-ansible-aws-gitlab-ce

Gitlab CE running on EC2 instance using Docker.
* Provisioned via Terraform
* Configured via Ansible

## Usage
**IMPORTANT:** The `master` branch may not be stable, check the `tags`/`releases` for refs you can pin to (E.g. `?ref=tags/x.y.z`)

For an example, see: [examples/full](examples/full)

## Inputs

| Name                    | Description                                                 | Type          | Default       |
| ----------------------- | ----------------------------------------------------------- | ------------- | ------------- |
| region                  | Region to setup in                                          | string        | us-west-1     |
| name                    | Name of service/stack                                       | string        | tak           |
| stage                   | Stage allowing for seperation of test/dev/prod environments | string        | test          |
| namespace               | Prefix value for stack                                      | string        | gitlab        |
| description             | Short description of the environment                        | string        | ''            |
| instance_type           | Instance type                                               | string        | t2.medium     |
| vpc_id                  | ID for VPC                                                  | string        |               |
| ssh_key_pair            | Name of local ssh public key file                           | string        |               |
| private_ssh_key         | Name of local ssh private key file                          | string        |               |
| ssl_cert_file           | Name of local ssl crt file                                  | string        |               |
| ssl_cert_key            | Name of local ssl crt key file                              | string        |               |
| ansible_user            | User on AMI that has root privileges                        | string        | ubuntu        |
| ansible_vars            | Variables to pass through to ansible playbook               | map           | `{}`          |
| data_storage_ebs_name   | Name of EBS volume for persistent storage                   | string        |               |

## Ansible Vars

| Name                                       | Description                                                 | Type          | Default                                                     |
| ------------------------------------------ | ----------------------------------------------------------- | ------------- | ----------------------------------------------------------- |
| gitlab_version                             | Version of GitLab-CE docker image to run                    | string        | 12.4.1-ce.0                                                 |
| domain_name                                | Domain name to reach gitlab                                 | string        | git.domain.com                                              |
| gitlab_letsencrypt_enable                  | Enable builtin letsencrypt ssl cert                         | boolean       | false                                                       |
| gitlab_letsencrypt_contact_email           | Contact email to use when requesting ssl cert               | string        | gitlab+letencrypt@domain.com                                |
| gitlab_letsencrypt_auto_renew              | Enable ssl cert auto renewals                               | boolean       | false                                                       |
| gitlab_letsencrypt_auto_renew_hour         | Cron hour to renew                                          | string        | 12                                                          |
| gitlab_letsencrypt_auto_renew_minute       | Cron minute to renew                                        | string        | 30                                                          |
| gitlab_letsencrypt_auto_renew_day_of_month | Cron day of month to renew                                  | string        | */7                                                         |
| gitlab_time_zone                           | Timezone of gitlab server                                   | string        | Pacific/Auckland                                            |
| gitlab_lfs_enabled                         | Enable Large File Store in gitlab                           | boolean       | true                                                        |
| gitlab_initial_root_password               | Root user password on first creation                        | string        | Ch4ng3:M3                                                   |
| gitlab_omniauth_enabled                    | Enable OMNI Auth                                            | boolean       | false                                                        |
| gitlab_omniauth_label                      | Button Label for OMNI Auth                                  | string        | G Suite                                                     |
| gitlab_omniauth_external_provider          | OMNI Auth Provider                                          | string        | saml                                                        |
| gitlab_omniauth_allow_single_sign_on       | Allow single signon from this provider                      | string        | saml                                                        |
| gitlab_omniauth_sync_email_from_provider   | Sync email from this provider                               | string        | saml                                                        |
| gitlab_omniauth_block_auto_created_users   | Block auto created users from being able to login           | boolean       | false                                                       |
| gitlab_omniauth_auto_link_ldap_user        | Auto link account to LDAP user                              | boolean       | false                                                       |
| gitlab_omniauth_sync_profile_from_provider | Sync profile from this provider                             | string        | saml                                                        |
| gitlab_omniauth_sync_profile_attribute     | Sync profile attribute                                      | string        | email                                                       |
| gitlab_omniauth_auto_link_saml_user        | Auto link SAML user                                         | boolean       | true                                                        |
| gitlab_omniauth_auto_sign_in_with_provider | Auto signin with provider (If session exists)               | string        | saml                                                        |
| gitlab_omniauth_idp_cert_fingerprint       | IdP Cert fingerprint                                        | string        | XX:DD:90:D2:15:9F:12:78:D5:XX:XX:88:XX:6E:XX:FD:XX:60:XX:B1 |
| gitlab_omniauth_idp_sso_id                 | IdP SSO ID from provider                                    | string        | XXXXXXXXX                                                   |
| gitlab_omniauth_name_identifier_format     |                                                             | string        | urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress      |
| gitlab_ldap_enable                         | Enable LDAP server                                          | boolean       | false                                                       |
| gitlab_ldap_host                           | LDAP Hostname                                               | string        | ldap.domain.com                                             |
| gitlab_ldap_port                           | LDAP Host Port                                              | string        | 636                                                         |
| gitlab_ldap_base                           | LDAP Base DN                                                | string        | ou=People,dc=domain,dc=com                                  |
| gitlab_ldap_uid                            | LDAP uid Field                                              | string        | uid                                                         |
| gitlab_ldap_method                         | LDAP connection method                                      | string        | tls                                                         |
| gitlab_ldap_bind_dn                        | LDAP Root DN                                                | string        | cn=Directory Manager                                        |
| gitlab_ldap_password                       | LDAP Manager Password                                       | string        | 87654321                                                    |
| gitlab_ldap_active_directory               | LDAP Use Active Directory                                   | boolean       | false                                                       |
| gitlab_ldap_allow_username_or_email_login  | LDAP Allow use of username or email to login                | boolean       | true                                                        |
| gitlab_ldap_block_auto_created_users       | LDAP Block auto created users from logging in               | boolean       | false                                                       |
| gitlab_email_from                          | Emails FROM address                                         | string        | gitlab@domain.com                                           |
| gitlab_email_display_name                  | Display name for FROM address                               | string        | 'GitLab @ Domain'                                           |
| gitlab_email_reply_to                      | Emails REPLY TO address                                     | string        | gitlab@domain.com                                           |
| gitlab_email_subject_suffix                | Suffix at end of email subject line                         | string        | 'GitLab @ Domain'                                           |
| gitlab_smtp_enable                         | Use External SMTP server                                    | boolean       | true                                                        |
| gitlab_smtp_address                        | SMTP server address                                         | string        | smtp.gmail.com                                              |
| gitlab_smtp_port                           | SMTP server port                                            | string        | 587                                                         |
| gitlab_smtp_user_name                      | SMTP username                                               | string        | noreply@domain.com                                          |
| gitlab_smtp_password                       | SMTP password                                               | string        | ************                                                |
| gitlab_smtp_domain                         | SMTP domain (Sometimes different from server address)       | string        | smtp.gmail.com                                              |
| gitlab_smtp_authentication                 | SMTP Authentication type                                    | string        | login                                                       |
| gitlab_smtp_enable_starttls_auto           | SMTP user StartTLS                                          | boolean       | true                                                        |
| gitlab_smtp_tls                            | SMTP over TLS                                               | boolean       | false                                                       |
| gitlab_smtp_openssl_verify_mode            | SMTP OpenSSL vertify mode                                   | string        | peer                                                        |
| gitlab_postgresql_enable                   | Enable builtin postgres server                              | boolean       | true                                                        |
| gitlab_postgresql_shared_buffers           | Postgres shared buffer size                                 | string        | 2GB                                                         |
| gitlab_db_adapter                          | External DB adapter to use                                  | string        | postgresql                                                  |
| gitlab_db_host                             | External DB server hostname                                 | string        | gitlab-db.domain.com                                        |
| gitlab_db_port                             | External DB server port                                     | string        | 5432                                                        |
| gitlab_db_database                         | External DB server DB name                                  | string        | database-name                                               |
| gitlab_db_username                         | External DB username                                        | string        | database-username                                           |
| gitlab_db_password                         | External DB password                                        | string        | database-password                                           |

## Outputs

| Name          | Description                           |
| ------------- | ------------------------------------- |
| public_ip     | Elastic IP of running gitlab instance |
