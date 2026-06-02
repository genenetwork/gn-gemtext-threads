# Precompute archive

We have a precompute archive which is basically a GEMMA output in lmdb form with metadata: fffdddbbbea7c16a605ef9bf7dba0790982e229c-gemma-GWA.tar.xz

Unpack with

```
tar xvJf fffdddbbbea7c16a605ef9bf7dba0790982e229c-gemma-GWA.tar.xz
```

Check metadata

```
jq < fffdddbbbea7c16a605ef9bf7dba0790982e229c-meta.json
```

showing

```
  "name": "CB_M_0104_M",
  "trait": "1436934_s_at_A",
  "time": "2024/01/07 02:42",
  "meta": {
    "type": "gemma-wrapper",
    "version": "0.99.7-pre1",
    "population": "BXD",
    "name": "CB_M_0104_M",
    "trait": "1436934_s_at_A",
    "url": "https://genenetwork.org/show_trait?trait_id=1436934_s_at_A&dataset=CB_M_0104_M",
    "archive_GRM": "46bfba373fe8c19e68be6156cad3750120280e2e-gemma-cXX.tar.xz",
    "archive_GWA": "fffdddbbbea7c16a605ef9bf7dba0790982e229c-gemma-GWA.tar.xz"
  }
```

To view the contents of the lmdb file you can unpack the meta field in lmdb that
looks like

```
meta{"type": "gemma-assoc", "version": 1.0, "key-format": ">cL", "rec-format": "=ffff", "log": {}}
```

This shows the python-style key format and the record format for the GEMMA mapped values. Unpack with

=> https://github.com/genetics-statistics/gemma-wrapper/blob/master/bin/view-gemma-mdb

you can see that file uses a 5 fields instead of 4 with

```
af,beta,se,l_mle,p_lrt = unpack('=fffff',rec)
```

basically p_lrt should be the last value of the record - i.e. each marker. More information can be found in /topics/systems/mariadb/precompute-publishdata.gmi

=> https://github.com/genenetwork/gn-gemtext-threads/blob/main/topics/systems/mariadb/precompute-publishdata.gmi