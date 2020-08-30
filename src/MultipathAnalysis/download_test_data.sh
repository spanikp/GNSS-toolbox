#!/bin/bash

# Downlading
curl ftp://epncb.oma.be/pub/obs/2019/020/GANP00SVK_R_20190200000_01D_30S_MO.crx.gz --output GANP00SVK_R_20190200000_01D_30S_MO.crx.gz
curl ftp://cddis.gsfc.nasa.gov/gps/products/mgex/2037/COD0MGXFIN_20190200000_01D_05M_ORB.SP3.gz --output COD0MGXFIN_20190200000_01D_05M_ORB.SP3.gz

# Unpacking
gzip -d GANP00SVK_R_20190200000_01D_30S_MO.crx.gz
gzip -d COD0MGXFIN_20190200000_01D_05M_ORB.SP3.gz

# Hatanaka conversion (https://terras.gsi.go.jp/ja/crx2rnx.html)
cat GANP00SVK_R_20190200000_01D_30S_MO.crx | crx2rnx - > GANP00SVK_R_20190200000_01D_30S_MO.19o
