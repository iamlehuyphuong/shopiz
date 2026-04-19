# Email Templates HTML Review

This document contains the final rendered HTML for all 39 email templates, alongside a syntax check.

## devise/mailer/confirmation_instructions
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi <%= @resource.name %>,</p>

<% account_user = @resource&.account_users&.first %>

<% if account_user&.inviter.present? && @resource.unconfirmed_email.blank? %>
  <p><%= account_user.inviter.name %>, with <%= account_user.account.name %>, has invited you to try out <%= global_config['BRAND_NAME'] || 'Chatwoot' %>.</p>
<% end %>

<% if @resource.confirmed? %>
  <p>You can login to your <%= global_config['BRAND_NAME'] || 'Chatwoot' %> account through the link below:</p>
<% else %>
  <% if account_user&.inviter.blank? %>
  <p>
    Welcome to <%= global_config['BRAND_NAME'] || 'Chatwoot' %>! We have a suite of powerful tools ready for you to explore. Before that we quickly need to verify your email address to know it's really you.
  </p>
  <% end %>
  <p>Please take a moment and click the link below and activate your account.</p>
<% end %>


<% if @resource.unconfirmed_email.present? %>
  <p><%= link_to 'Confirm my account', frontend_url('auth/confirmation', confirmation_token: @token) %></p>
<% elsif @resource.confirmed? %>
  <p><%= link_to 'Login to my account', frontend_url('auth/sign_in') %></p>
<% elsif account_user&.inviter.present? %>
  <p><%= link_to 'Confirm my account', frontend_url('auth/password/edit', reset_password_token: @resource.send(:set_reset_password_token)) %></p>
<% else %>
  <p><%= link_to 'Confirm my account', frontend_url('auth/confirmation', confirmation_token: @token) %></p>
<% end %>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## devise/mailer/password_change
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello <%= @resource.email %>!</p>

<p>We're contacting you to notify you that your password has been changed.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## devise/mailer/reset_password_instructions
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello <%= @resource.email %>!</p>

<p>Someone has requested a link to change your password. You can do this through the link below.</p>

<p><%= link_to 'Change my password', frontend_url('auth/password/edit', reset_password_token: @token) %></p>

<p>If you didn't request this, please ignore this email.</p>
<p>Your password won't change until you access the link above and create a new one.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## devise/mailer/unlock_instructions
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello <%= @resource.email %>!</p>

<p>Your account has been locked due to an excessive number of unsuccessful sign in attempts.</p>

<p>Click the link below to unlock your account:</p>

<p><%= link_to 'Unlock my account', unlock_url(@resource, unlock_token: @token) %></p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_compliance_mailer/account_deleted
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>This is a notification to inform you that an account has been permanently deleted from your Chatwoot instance.</p>

<p>
  <strong>Chatwoot Installation:</strong> <br>
  <strong>Account ID:</strong> <br>
  <strong>Account Name:</strong> <br>
  <strong>Deletion due at:</strong> <br>
  <strong>Deleted At:</strong> <br>
  <strong>Deletion Reason:</strong> 
</p>


<p>
  <strong>Deleted Users:</strong> None
</p>


<p>This email serves as a record for compliance purposes.</p>

<p>Thank you,<br>
Chatwoot System</p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/account_deletion_for_inactivity
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>We've noticed that your Chatwoot account <strong></strong> has been inactive for some time. Because of this, it's scheduled for deletion on <strong></strong>.</p>

<p><strong>How do I keep my account?</strong></p>

<p>Log in to your Chatwoot account before <strong></strong>. From your account settings, you can <a href="https://example.com">cancel the deletion</a> and continue using your account.</p>

<p><strong>What happens if I don't cancel?</strong></p>

<p>Unless you cancel the account deletion before <strong></strong>, your account and all associated data — including conversations, contacts, reports, and settings — will be permanently deleted.</p>

<p><strong>Why are we doing this?</strong></p>

<p>To keep things secure and efficient, we regularly remove inactive accounts so our systems remain optimized for active teams.</p>

<p>If you have any questions, feel free to reach us at <a href="mailto:hello@chatwoot.com">hello@chatwoot.com</a>.</p>

<p>— The Chatwoot Team</p>



                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/account_deletion_user_initiated
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>An account administrator has requested deletion of the Chatwoot account <strong></strong>. The account is scheduled for deletion on <strong></strong>.</p>

<p><strong>What happens next?</strong></p>

<ul>
  <li>The account will remain accessible until the scheduled deletion date.</li>
  <li>After that, all data including conversations, contacts, integrations, and settings will be permanently removed.</li>
  </ul>

<p>If you change your mind before the deletion date, you can <a href="https://example.com">cancel this request</a> by visiting your account settings.</p>

<p>— The Chatwoot Team</p>



                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/automation_rule_disabled
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>The automation rule <b></b> has been disabled becuase it has invalid conditions.</p>
<p>This typically happens when you delete any custom attributes which are still being used in automation rules.</p>

<p>
Click <a href="https://example.com">here</a> to update the conditions.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/contact_export_complete
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi</p>


<p>Your contact export file is ready to download.</p>

<p>
Click <a href="https://example.com">here</a> to download the export file.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/contact_import_complete
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your contact import has been completed. Please check the contacts tab to view the imported contacts.</p>

<p>Number of records imported: </p>

<p>Number of records failed: </p>


  <p>
  Click <a href="https://example.com" target="_blank">here</a> to view failed records.
  </p>


                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/account_notification_mailer/contact_import_failed
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your contact import has failed. It appears that the CSV file you uploaded may not be valid. We kindly request that you review the file and ensure it complies with the required format.<p/>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/automation_rule_disabled
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>The automation rule <b></b> has been disabled becuase it has invalid conditions.</p>
<p>This typically happens when you delete any custom attributes which are still being used in automation rules.</p>

<p>
Click <a href="https://example.com">here</a> to update the conditions.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/contact_export_complete
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi</p>


<p>Your contact export file is ready to download.</p>

<p>
Click <a href="https://example.com">here</a> to download the export file.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/contact_import_complete
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your contact import has been completed. Please check the contacts tab to view the imported contacts.</p>

<p>Number of records imported: </p>

<p>Number of records failed: </p>


  <p>
  Click <a href="https://example.com" target="_blank">here</a> to view failed records.
  </p>


                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/contact_import_failed
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your contact import has failed. It appears that the CSV file you uploaded may not be valid. We kindly request that you review the file and ensure it complies with the required format.<p/>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/dialogflow_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>Your Dialogflow integration was disconnected because of permission issues. To resolve this, please delete the integration from the admin dashboard and reconnect it using new credentials.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/email_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your email inbox has been disconnected due to configuration errors. </p>
<p>Please update it to continue receiving messages.</p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/facebook_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your Facebook Inbox Access has expired. </p>
<p>Please reconnect Facebook Page to continue receiving messages.</p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/instagram_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your Instagram Inbox Access has expired. </p>
<p>Please reconnect Instagram to continue receiving messages.</p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/slack_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your Slack integration has expired. To continue receiving messages on Slack, please delete the integration and connect your workspace again. </p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/channel_notifications_mailer/whatsapp_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your Whatsapp Access has expired. </p>
<p>Please reconnect Whatsapp to continue receiving messages.</p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/integrations_notification_mailer/dialogflow_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>

<p>Your Dialogflow integration was disconnected because of permission issues. To resolve this, please delete the integration from the admin dashboard and reconnect it using new credentials.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/administrator_notifications/integrations_notification_mailer/slack_disconnect
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello,</p>

<p>Your Slack integration has expired. To continue receiving messages on Slack, please delete the integration and connect your workspace again. </p>

<p>
Click <a href="https://example.com">here</a> to re-connect.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/assigned_conversation_new_message
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>You have received a new message in your assigned conversation.</p>

<p>
Click <a href="https://example.com">here</a> to get cracking.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/conversation_assignment
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>Time to save the world. A new conversation has been assigned to you</p>



<p>
Click <a href="https://example.com">here</a> to get cracking.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/conversation_creation
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice</p>

<p>
  A new conversation (<a href="https://example.com">#</a>) has been created in .
  <strong></strong> wrote:
</p>



                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/conversation_mention
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice, </p>

<p>You've been mentioned in a conversation. <b></b> wrote:</p>
<blockquote style="box-sizing:border-box; padding:8px 16px; margin:0 0 20px; font-size:14px; border-left:5px solid #eeeeee">
  
</blockquote>

<p><b>Previous messages:</b></p>

<p>
  <a href="https://example.com">View Message</a>
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/participating_conversation_new_message
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>You have received a new message in a conversation you are participating.</p>

<p>Click <a href="https://example.com">here</a> to get cracking.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/sla_missed_first_response
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>
  Conversation # in  
  has missed the SLA for first response  under policy .
</p>

<p>
<a href="https://example.com">Please address immediately.</a>
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/sla_missed_next_response
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>
  Conversation # in  
  has missed the SLA for next response under policy ..
</p>

<p>
<a href="https://example.com">Please address immediately.</a>
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/agent_notifications/conversation_notifications_mailer/sla_missed_resolution
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice,</p>

<p>
  Conversation # in  
  has missed the SLA for resolution time under policy .
</p>

<p>
<a href="https://example.com">Please address immediately.</a>
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/conversation_reply_mailer/conversation_transcript
**Status**: ❌ Syntax Errors Found

### Errors:
- `109:42: ERROR: Opening and ending tag mismatch: td and table`
- `110:38: ERROR: Opening and ending tag mismatch: tr and table`

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <% @messages.each do |message| %>
  <tr>
    <td>
      <b><%= message.sender&.try(:available_name) || message.sender&.name || '' %></b>
      <% if message.conversation.inbox&.inbox_type == 'Email' %>
        <div style="font-size: 90%; color: #899096; line-height: 16px">
          <% if message.content_attributes.dig(:email, :from).present? %>
            <div>From: <%= message.content_attributes.dig(:email, :from).join(", ") %></div>
          <% else %>
            <div>From: <%= message.sender&.try(:email) %></div>
          <% end %>

          <% if message.content_attributes.dig(:email, :subject).present? %>
            <div>Subject: <%= message.content_attributes.dig(:email, :subject) %></div>
          <% end %>

          <% if message.content_attributes[:to_emails].present? %>
            <div>To: <%= message.content_attributes[:to_emails].join(", ") %></div>
          <% end %>
          <% if message.content_attributes[:cc_emails].present? %>
            <div>CC: <%= message.content_attributes[:cc_emails].join(", ") %></div>
          <% end %>
          <% if message.content_attributes[:bcc_emails].present? %>
            <div>BCC: <%= message.content_attributes[:bcc_emails].join(", ") %></div>
          <% end %>
        </div>
      <% end %>
    </td>
  </tr>
  <tr>
    <td style="padding-bottom: 32px;">
      <% if message.content %>
        <%= ChatwootMarkdownRenderer.new(message.content).render_message %>
      <% end %>
      <% if message.attachments.present? %>
        <p>Attachments:</p>
        <% message.attachments.each do |attachment| %>
          <p><a href="<%= attachment.file_url %>" target="_blank"><%= attachment.file.filename.to_s %></a></p>
        <% end %>
      <% end %>
      <p style="font-size: 90%; font-size: 90%;color: #899096;margin-top: -8px; margin-bottom: 0px;">
      <% if @inbox.timezone.present? %>
        <%= message.created_at.in_time_zone(@inbox.timezone).strftime('%b %d, %I:%M %p %Z') %>
      <% else %>
        <%= message.created_at.strftime('%b %d, %I:%M %p %Z') %>
      <% end %>
      </p>
    </td>
  </tr>
<% end %>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/conversation_reply_mailer/email_reply
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <% if @message.content_attributes.dig('email', 'html_content', 'reply').present? %>
<%= @message.content_attributes.dig('email', 'html_content', 'reply').html_safe %>
<% elsif @message.content %>
<%= @message.outgoing_content.html_safe %>
<% end %>
<% if @large_attachments.present? %>
<p>Attachments:</p>
<% @large_attachments.each do |attachment| %>
<p><a href="<%= attachment.file_url %>" target="_blank"><%= attachment.file.filename.to_s %></a></p>
<% end %>
<% end %>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/conversation_reply_mailer/reply_with_summary
**Status**: ❌ Syntax Errors Found

### Errors:
- `85:13: ERROR: Unexpected end tag : p`
- `91:42: ERROR: Opening and ending tag mismatch: td and table`
- `92:38: ERROR: Opening and ending tag mismatch: tr and table`

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi <%= @contact.name %>,</p>

<p>You have new messages on your conversation.</p>

<% @messages.each do |message| %>
  <tr>
    <td>
      <b><%= message.incoming? ? 'You' : message.sender&.available_name || message.sender&.name || 'Bot' %></b>
    </td>
  </tr>
  <tr>
    <td style="padding: 0px 16px; margin: 4px 0 8px 0; background: #F5FAFF; border-radius: 5px; display: inline-block; font-family: 'Helvetica Neue',Tahoma,Arial,sans-serif; text-align: start; unicode-bidi: plaintext;">
      <% if (message.content_type == 'input_csat' && message.message_type == 'template') %>
        <p>Click <a href="<%= message.conversation.csat_survey_link %>" _target="blank">here</a> to rate the conversation.</p>
      <% elsif message.content.present? %>
        <%= ChatwootMarkdownRenderer.new(message.content).render_message %>
      <% end %>
      <% if message.attachments.count.positive? %>
        <p>
          <% if message.content.present? %>
            <hr style="border: 0; border-bottom: 1px solid #AEC3D5;"/>
          <% end %>
          Attachments:
          <% message.attachments.each_with_index do |attachment, index| %>
            <% if index > 0 %><br /><% end %>
            <a href="<%= attachment.file_url %>" target="_blank"><%= attachment.file.filename.to_s %></a>
          <% end %>
        </p>
      <% end %>
    </td>
  </tr>
<% end %>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/conversation_reply_mailer/reply_without_summary
**Status**: ❌ Syntax Errors Found

### Errors:
- `69:7: ERROR: Unexpected end tag : p`

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <% @messages.each do |message| %>
  <p style="font-family: Roboto,"Helvetica Neue",Tahoma,Arial,sans-serif; text-align: start; unicode-bidi: plaintext;">
    <% if message.content %>
      <%= ChatwootMarkdownRenderer.new(message.content).render_message %>
    <% end %>
    <% if message.attachments.present? %>
      <p>Attachments:</p>
      <% message.attachments.each do |attachment| %>
        <p><a href="<%= attachment.file_url %>" target="_blank"><%= attachment.file.filename.to_s %></a></p>
      <% end %>
    <% end %>
  </p>
<% end %>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/portal_instructions_mailer/send_cname_instructions
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hello there,</p>
<p>To complete the setup of your help center, you'll need to update the DNS settings for your custom domain: <strong></strong>.</p>
<p>Please add the following CNAME record to your DNS provider's configuration:</p>

<p><strong></strong></p>

<p>Step-by-step Instructions:</p>

<ol>
  <li>Log in to your DNS provider’s dashboard</li>
  <li>Go to the DNS management section</li>
  <li>Create a new CNAME record using the information above</li>
  <li>Save the changes and allow up to 24 hours for the DNS to propagate</li>
</ol>

<p>Once the DNS record is live, your custom domain will automatically be secured with an SSL certificate.</p>

<p>If you have any questions or need help, feel free to reach out to our support team—we’re here to assist you.</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/team_notifications/automation_notification_mailer/conversation_creation
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>This is the mail from Automation System</p>

<p></p>

<p>
Click <a href="https://example.com">here</a> to get cracking.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/team_notifications/automation_notification_mailer/conversation_updated
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice</p>


<p></p>

<p>
Click <a href="https://example.com">here</a> to get cracking.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

## mailers/team_notifications/automation_notification_mailer/message_created
**Status**: ✅ Syntax Correct

### Final HTML Source:
```html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=device-width" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Shopiz Email</title>
    <style type="text/css">
        body { background-color: #F1F5F9; font-family: 'Nunito Sans', Helvetica, Arial, sans-serif; margin: 0; -webkit-font-smoothing: antialiased; }
        img { max-width: 100%; border: none; text-decoration: none; }
        
        @media only screen and (max-width: 640px) {
            .container { width: 100% !important; padding: 10px !important; }
            .content-wrap { padding: 25px 20px !important; }
            .header-box { padding: 25px 20px !important; }
        }
    </style>
</head>
<body style="background-color: #F1F5F9;">
    
    

    

    <table width="100%" bgcolor="#F1F5F9" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="container" width="600" style="display: block; margin: 0 auto; max-width: 600px; padding: 30px 0;">
                
                <table width="100%" bgcolor="#ffffff" style="border-radius: 24px; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05); border-top: 5px solid #F97316;">
                    
                    <tr>
                        <td class="header-box" style="background: linear-gradient(180deg, #FFF7ED 0%, #FFFFFF 100%); padding: 30px 20px; text-align: center;">
                            <img src="/brand-assets/logo_thumbnail.svg" width="80" alt="Shopiz" style="display: block; margin: 0 auto;" />
                            
                            <div style="margin-top: 8px; color: #F97316; font-size: 12px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase;">
                                
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 45px;">
                            <div style="height: 1px; width: 100%; background-color: #FEE2E2; opacity: 0.5;"></div>
                        </td>
                    </tr>

                    <tr>
                        <td class="content-wrap" style="padding: 35px 45px 45px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="padding-bottom: 25px; text-align: left;">
                                        <span style="display: inline-block; padding: 6px 16px; background-color: #3b82f6; color: #ffffff; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px;">
                                            Notice
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="font-size: 15px; line-height: 1.6; color: #334155; text-align: left;">
                                        <p>Hi Alice</p>


<p></p>

<p>
Click <a href="https://example.com">here</a> to get cracking.
</p>

                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="text-align: center; padding: 25px 20px; font-size: 12px; color: #94A3B8;">
                            <p style="margin: 0 0 5px;">&copy; 2026 <strong></strong>. All Rights Reserved.</p>
                            <div style="margin-top: 5px;">
                                <a href="" style="color: #F97316; text-decoration: none; font-weight: 600;">Website</a>
                            </div>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>
</html>

```

---

