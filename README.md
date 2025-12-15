
### Terraform

```
Prepare
> terraform plan


Create resources
> terrafrom apply


Clean environment
> terraform destroy
```

### AWS credential Powershell

```
$Env:AWS_ACCESS_KEY_ID="アクセスキー"
$Env:AWS_SECRET_ACCESS_KEY="シークレットアクセスキー"
```

For Example
```
$Env:AWS_DEFAULT_REGION="リージョン"
$Env:AWS_ACCESS_KEY_ID="アクセスキー"
$Env:AWS_SECRET_ACCESS_KEY="シークレットアクセスキー"
$Env:AWS_SESSION_TOKEN="STSトークン"
```



### Output ssh pem file

on powershell after download do following to set file permission to 0400 (chmod 0400 equivalent)

```
$ icacls.exe confluent-demo-key.pem /reset 
$ icacls.exe confluent-demo-key.pem /grant:r "$($env:username):(r)"
$ icacls.exe confluent-demo-key.pem /inheritance:r
```


