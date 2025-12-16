# 環境ごとのmemo 


## AWS dependancy
python3 -m pip install --upgrade attrs
python3 -m pip install --upgrade certifi
python3 -m pip install --upgrade httpx
python3 -m pip install --upgrade cachetools
python3 -m pip install --upgrade authlib
python3 -m pip install --upgrade fastavro

python3 -m pip install --upgrade attrs certifi httpx cachetools authlib fastavro

## MEMO (特にPwoershell実行)

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

