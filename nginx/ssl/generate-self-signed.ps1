$certSubject = "CN=blbgensixai.club"
$dnsNames = @("blbgensixai.club", "*.blbgensixai.club", "localhost")
$ipAddresses = @("127.0.0.1")
$outputPath = "C:\stash\nginx\ssl"
$validDays = 365

$cert = New-SelfSignedCertificate `
    -Subject $certSubject `
    -DnsName $dnsNames `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -NotAfter (Get-Date).AddDays($validDays) `
    -KeySpec KeyExchange `
    -TextExtension @("2.5.29.19={text}CA=false")

$rootCert = New-SelfSignedCertificate `
    -Subject "CN=blbgensixai.club CA" `
    -CertStoreLocation "cert:\LocalMachine\Root" `
    -NotAfter (Get-Date).AddDays($validDays) `
    -KeySpec KeyExchange `
    -TextExtension @("2.5.29.19={text}CA=true")

Export-Certificate -Cert $cert -FilePath "$outputPath\server.crt" -Type CERT
Export-Certificate -Cert $rootCert -FilePath "$outputPath\ca.crt" -Type CERT

$privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
[System.IO.File]::WriteAllBytes("$outputPath\server.key", $privateKey.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob))

Write-Host "Certificates generated successfully at $outputPath"
Write-Host "Server cert: server.crt"
Write-Host "Private key: server.key"
Write-Host "CA cert: ca.crt"
Write-Host "CA cert added to Windows Trusted Root Store"
