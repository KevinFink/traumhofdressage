#! /usr/bin/perl

use strict;
use CGI qw/:standard/;
use Mail::Send;

my $template = '/home/traumhof/traumhofdressage/clinic_registration.html';
my $logfile = '/home/traumhof/traumhofdressage/registrations.txt';
my @bcc = qw(jessica@fink.com kevin@fink.com);
my $lunch_fee = 15;
my $default = 'lientje_apr2013';

my $today = `date +%Y%m%d`;
my $response;
my $error = -1;
my $cost = 0;
my $enable_paypal = 1;

my $data = {
  lientje_apr2013 => {
    audit_fee => 35,
    audit_fee2 => 60,
    ei_audit_fee => undef,
    clinic_name => 'Lientje Schueler',
    date => 20130414,
    sat_long => 'Saturday, April 13th, 2013',
    sun_long => 'Sunday, April 14th, 2013',
    both_long => 'Saturday and Sunday, April 13th and April 14th, 2013',
    party => 1,
    late => 0,
    lunch_offered => 0,
  },
  lientje_jul2013 => {
    audit_fee => 35,
    audit_fee2 => 60,
    ei_audit_fee => undef,
    clinic_name => 'Lientje Schueler',
    date => 20130728,
    sat_long => 'Saturday, July 27th, 2013',
    sun_long => 'Sunday, July 28th, 2013',
    both_long => 'Saturday and Sunday, July 27th and 28th, 2013',
    party => 1,
    late => 0,
    lunch_offered => 0,
  },
  lientje_sep2013 => {
    audit_fee => 35,
    audit_fee2 => 60,
    ei_audit_fee => undef,
    clinic_name => 'Lientje Schueler',
    date => 20130929,
    sat_long => 'Saturday, September 28th, 2013',
    sun_long => 'Sunday, September 29th, 2013',
    both_long => 'Saturday and Sunday, September 28th and 29th, 2013',
    party => 1,
    late => 0,
    lunch_offered => 0,
  },
  lientje_oct2013 => {
    audit_fee => 35,
    audit_fee2 => 60,
    ei_audit_fee => undef,
    clinic_name => 'Lientje Schueler',
    date => 20131027,
    sat_long => 'Saturday, October 26th, 2013',
    sun_long => 'Sunday, October 27th, 2013',
    both_long => 'Saturday and Sunday, October 26th and 27th, 2013',
    party => 1,
    late => 0,
    lunch_offered => 0,
  },
  shannon_nov2011 => {
    audit_fee => 35,
    audit_fee2 => 70,
    ei_audit_fee => undef,
    clinic_name => 'Shannon Peters',
    date => 20111113,
    sat_long => 'Saturday, November 12th, 2011',
    sun_long => 'Sunday, November 13th, 2011',
    both_long => 'Saturday and Sunday, November 12th and 13th, 2011',
    late => 0,
  },
  david_mar2012 => {
    audit_fee => 35,
    audit_fee2 => 70,
    ei_audit_fee => undef,
    clinic_name => 'David Blake',
    date => 20120325,
    sat_long => 'Saturday, March 24th, 2012',
    sun_long => 'Sunday, March 25th, 2012',
    both_long => 'Saturday and Sunday, March 24th and 25th, 2012',
    late => 1,
  },
  steffen_may2011 => {
    audit_fee => 55,
    audit_fee2 => 100,
    ei_audit_fee => undef,
    clinic_name => 'Steffen Peters',
    sat_long => 'Saturday, May 14th, 2011',
    sun_long => 'Sunday, May 15th, 2011',
    both_long => 'Saturday and Sunday, May 14th and 15th, 2011',
    late => 1,
    lunch_offered => 1,
  },
};

my $cgi = new CGI;
my $count = scalar $cgi->param();

my $custom;
if($cgi->param('id')) {
  $custom = $data->{$cgi->param('id')};
  if(!defined $custom) {
    warn "Couldn't find data structure for id ",$cgi->param('id'),". Using $default\n";
    $custom = $data->{$default};
  }
}
else {
  warn "ID not passed. Using $default\n";
  $custom = $data->{$default};
}

my $audit_fee = $custom->{'audit_fee'};
my $audit_fee2 = $custom->{'audit_fee2'} || $audit_fee*2;
my $clinic_name = $custom->{'clinic_name'};
my $late = $custom->{'late'} || 0;
my $lunch_offered = $custom->{'lunch_offered'} || 0;
my $party = $custom->{'party'} || 0;

if($count > 1)
{
  $error = 0;

  if(defined $custom->{'date'} && $today > $custom->{'date'}) {
    $error = 1;
    $response .= "<li>That clinic date has already passed!</li>\n";
  }

  unless($cgi->param('firstname'))
  {
    $error = 1;
    $response .= "<li>Must specify First Name</li>\n";
  }
  unless($cgi->param('lastname'))
  {
    $error = 1;
    $response .= "<li>Must specify Last Name</li>\n";
  }
  unless($cgi->param('email'))
  {
    $error = 1;
    $response .= "<li>Must specify Email Address</li>\n";
  }
  if($cgi->param('vip') eq 'Groom')
  {
    if($cgi->param('groomfor') eq '')
    {
      $error = 1;
      $response .= "<li>Must specify who you're grooming for</li>\n";
    }
  }

  if($cgi->param('vip') eq 'EI Member' && defined $custom->{'ei_audit_fee'}) {
    $audit_fee = $custom->{'ei_audit_fee'};
  } elsif($cgi->param('vip') ne "N/A") {
    $audit_fee = 0;
      $audit_fee2 = 0;
  }

  my %selected;
  if($cgi->param('date') eq 'sat' || $cgi->param('date') eq 'sun')
  {
    $cost += $audit_fee;
    $selected{'one'} = 'selected';
    $selected{'both'} = '';
  }
  elsif($cgi->param('date') eq 'both')
  {
    $cost += $audit_fee2;
    $selected{'one'} = '';
    $selected{'both'} = 'selected';
  }
  else
  {
    $error = 1;
    $response .= "<li>Error choosing audit date(s)?!?!</li>\n";
  }

  if($cgi->param('satlunch') && $cgi->param('satlunch') ne 'none')
  {
    $cost += $lunch_fee;
  }
  if($cgi->param('sunlunch') && $cgi->param('sunlunch') ne 'none')
  {
    $cost += $lunch_fee;
  }

  if(($cgi->param('satlunch') eq 'special' || $cgi->param('sunlunch') eq 'special') &&
    !$cgi->param('lunchnotes'))
  {
    $error = 1;
    $response .= "<li>Please explain your special lunch requirements</li>\n";
  }

  if($cgi->param('lunchnotes') =~ /http/) {
    $error = 1;
    $response .= "<li>Registration problem. Please contact us to continue.</li>\n";
  }

  if($error)
  {
    $response = qq{
      <strong style="text-color: red;">Please fix the following errors and re-submit:</strong>
      <ul style="text-color: red;">
        $response
      </ul>
    };
  
  }
  else
  {
    my $code = uc substr($cgi->param('lastname').$cgi->param('firstname'),0,3)
      . join('', (2..9)[rand 8, rand 8, rand 8]);
  
    my $cost_string = sprintf('$%0.2f',$cost);
  
    $response = qq{
      <div class="message" style="clear: both; background:#999999; width: 800px; font-family: 'ArialMT'; padding: 10px;">
      Thank you for registering for the $clinic_name clinic. You should receive an email confirmation shortly.
      Your confirmation code is <strong>$code</strong>. };

    if($cost > 0) {
          if($enable_paypal && !$late) {
              $response .= qq{
Please pay the appropriate amount via PayPal or send a check for $cost_string to:
<pre>
  LDF Farms
  32040 NE 112th St
  Carnation, WA 98014
</pre>
Please reference your confirmation code (or codes, if you are paying for multiple
people with a single check) on the check.
        };
          } elsif($enable_paypal && $late) {
              $response .= qq{Please pay the appropriate amount via PayPal or bring a check for $cost_string to the clinic.};
          } elsif($late) {
              $response .= qq{Please bring a check for $cost_string to the clinic.};
          } else {
              $response .= qq{
Please send a check for $cost_string to:
<pre>
  LDF Farms
  32040 NE 112th St
  Carnation, WA 98014
</pre>
Please reference your confirmation code (or codes, if you are paying for multiple
people with a single check) on the check.
        };
          }
          if($enable_paypal) {
              $response .= qq{
<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="CVH293MZM8NNG">
<table>
<tr><td><input type="hidden" name="on0" value="Options"></td></tr><tr><td><select name="os0">
  <option value="Auditing - both days" selected="$selected{'both'}">Auditing - both days \$60.00 USD</option>
  <option value="Auditing - one day" selected="$selected{'one'}">Auditing - one day \$35.00 USD</option>
</select> </td></tr>
</table>
<input type="hidden" name="currency_code" value="USD">
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_paynowCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
              };
          }
        }

        $response .= qq{
      <p>If you have not already filed a
        <a href="/liability_release.pdf" target="_new">liability release form</a>
        with us, please download the form, sign it, and return with your check.
      </p>
  
      <p>
        Thank you for registering for the clinic. We are looking forward to seeing you!
      </p>

      <p>
        Note: If you don't see a confirmation message within the next couple
        of minutes, please check your spam folder for a message with the subject
        "Traumhof Dressage Clinic Registration".
      </p>
      </div>
    };
  
    open(OUT,">>$logfile");
    foreach my $param ($cgi->param)
    {
      print OUT $param,"\t",$cgi->param($param),"\n";
    }
    print OUT "cost: $cost\n";
    print OUT "confirmation: $code\n";
    print OUT "registration date: ", `date`, "\n\n";
    close OUT;
  
    my $msg = new Mail::Send;
    $msg->to($cgi->param('email'));
    $msg->bcc(@bcc);
    $msg->add('from','Traumhof Dressage Clinic Registration <clinics@traumhofdressage.com>');
    $msg->subject('Traumhof Dressage Clinic Registration');
    my $fh = $msg->open;

    my $days;
    if($cgi->param('date') eq 'sat')
    {
      $days = $custom->{'sat_long'};
    }
    elsif($cgi->param('date') eq 'sun')
    {
      $days = $custom->{'sun_long'};
    }
    else
    {
      $days = $custom->{'both_long'};
    }

    my $meals = '';
    if($lunch_offered) {
      $meals = "\n";
      if($cgi->param('satlunch') eq 'none' && $cgi->param('sunlunch') eq 'none')
      {
        $meals .= "You did not request a yummy lunch from The Grange.";
      }
      if($cgi->param('satlunch') ne 'none')
      {
        $meals .= "You requested a " . $cgi->param('satlunch') . " box lunch for Saturday. (\$$lunch_fee)\n";
      }
      if($cgi->param('sunlunch') ne 'none')
      {
        $meals .= "You requested a " . $cgi->param('sunlunch') . " box lunch for Sunday. (\$$lunch_fee)\n";
      }
      if($cgi->param('lunchnotes'))
      {
        $meals .= "We will pass your special dietary requirements of:\n".
          $cgi->param('lunchnotes') .
          "\non to The Grange Cafe.\n";
      }
    }
    my $name = $cgi->param('firstname') . ' ' . $cgi->param('lastname');

    print $fh qq{
      Dear $name,

      Thank you for registering for the $clinic_name clinic at Traumhof on $days.  Your confirmation code is $code.
      $meals

    };

    if($cost > 0) {
      if($enable_paypal) {
        print $fh "If you did not already pay via PayPal, ";
      }
      if($late) {
        print $fh "please bring a check for $cost_string to the clinic.\n";
      } else {
        print $fh qq{
          please send a check for $cost_string to:
          LDF Farms
          32040 NE 112th St
          Carnation, WA 98014

          Please reference your confirmation code (or codes, if you are paying for
          multiple people with a single check) on the check.

        };
      }
    }

    print $fh qq{
      If you do not already have a liability release form on file with us,
      please download the form from http://www.traumhofdressage.com/liability_release.pdf,
      sign it, and return with your check.

      Thank you for registering for the clinic. We are looking forward to seeing you here!

    };
    
#    print $fh "\nSubmitted values:\n";
#    foreach my $param ($cgi->param)
#    {
#      print $fh $param,"\t",$cgi->param($param),"\n";
#    }
    $fh->close || ($error = 2);
  
    $msg = new Mail::Send;
    $msg->to('kevin@fink.com');
    $msg->add('from','Traumhof Dressage Clinic Registration <clinics@traumhofdressage.com>');
    $msg->subject('Traumhof Dressage Clinic Registration');
    $fh = $msg->open;

    foreach my $param ($cgi->param)
    {
      print $fh $param,"\t",$cgi->param($param),"\n";
    }
    print $fh "cost: $cost\n";
    print $fh "confirmation: $code\n";
    print $fh "registration date: ", `date`, "\n\n";
    $fh->close;

    if($error)
    {
      $response = qq{
        <strong style="text-color: red;">Warning: There was an error submitting your
          registration! Please try again, or contact Jessica for help.</strong>
        $response};
    }
  }
}

if($error != 0)
{
  $response .= qq{
    <div style="clear: both; background:#999999; width: 800px;">
    <p style="font-size:1.2em">Thank you for your interest in the $clinic_name clinic on $custom->{'both_long'}!
      Auditing is \$$custom->{'audit_fee'} per day
      (or \$$custom->{'audit_fee2'} for the weekend).</p>
  };
  if($lunch_offered) {
    $response .= qq{
        <p>
          We will once again be offering delicious box lunches from
          <a href="http://www.grangecafe.com/" target="_new">The Grange Cafe</a>. They are \$$lunch_fee each
          and include a drink and dessert. They will be made and delivered each day, so must
          be ordered and paid for in advance. You can choose from regular or vegetarian options,
          or even specify special dietary needs - The Grange is very good at providing custom
          meals.
        </p>
      };
  }
  $response .= qq{Please fill out the form to sign up:</p>}
    .start_form(-action=>'/cgi-bin/submit_audit_registration.pl',-method=>'get')
    .hidden('id',$cgi->param('id'))
    .qq{
    <table border="0" width="100%">
      <tr class="oddline">
        <td>First Name:</td>
        <td>}.textfield('firstname').qq{</td>
      </tr>
      <tr>
        <td>Last Name:</td>
        <td>}.textfield('lastname').qq{</td>
      </tr>
      <tr class="oddline">
        <td>Email Address:</td>
        <td>}.textfield('email').qq{</td>
      </tr>
      <tr>
        <td>Attending:</td>
        <td>}.
          radio_group(-name=>'date',
            -values=>['sat','sun','both'],
            -default=>'both',
            -labels=>{'sat'=>'Sat','sun'=>'Sun','both'=>'Both'}).qq{
        </td>
      </tr>
      <tr class="oddline">
        <td>VIP:</td>
        <td>
          <label><input type="radio" checked="checked" value="N/A" name="vip">N/A</label><br>
          <label><input type="radio" value="Boarder" name="vip">Traumhof Boarder</label><br>
          <label><input type="radio" value="Rider" name="vip">Rider</label><br>
          <label><input type="radio" value="Groom" name="vip">Groom for <input type="text" name="groomfor"/></label><br>
        </td>
      </tr>
      };
  if($party) {
    $response .= qq{
      <tr>
        <td>Attending Saturday<br>evening party?</td>
        <td>}.
          radio_group(-name=>'party',
            -values=>['Yes','No'],
            -default=>'No').qq{
        </td>
      </tr>
    };
  }
  if($lunch_offered) {
    $response .= qq{
      <tr class="oddline">
        <td>Sat Lunch:</td>
        <td>}.
          radio_group(-name=>'satlunch',
            -values=>['none','regular','vegetarian','special'],
            -default=>'none').qq{
        </td>
      </tr>
      <tr>
        <td>Sun Lunch:</td>
        <td>}.
          radio_group(-name=>'sunlunch',
  -values=>['none','regular','vegetarian','special'],
  -default=>'none').qq{
        </td>
      </tr>
      <tr class="oddline">
        <td>Special<br/>Dietary<br/>Requirements:</td>
        <td>}.textarea(-name=>'lunchnotes',-rows=>5,-columns=>40).qq{</td>
      </tr>};
  }
    $response .= qq{
      <tr>
        <td colspan="2">}
          .submit(-value=>'Submit Registration')
          .defaults('Clear').qq{
        </td>
      </tr>
    </table>
  </form>
  </div>
  };
}

print $cgi->header;

open(IN,"<$template");
while(<IN>)
{
  if(/<!--##INSERT_FORM##-->/)
  {
    print $response;
    next;
  }
  print;
}
close IN;
