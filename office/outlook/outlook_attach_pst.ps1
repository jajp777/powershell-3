$myPSTpath = "%userprofile%\contactEstel.pst"
$outlook=new-object -com Outlook.Application
$outlook.session.AddStore($myPSTpath)