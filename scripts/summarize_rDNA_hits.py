#!/usr/bin/env python3
import os
ofolder ="results"
indir=os.path.join(ofolder,'barrnap')
moltypes = ["16S","ITS","18S"]
for mtype in moltypes:
    targetext = "{}_hits.blastn.tab".format(mtype)
    targetfolder = os.path.join(ofolder,"{}_tree".format(mtype))
    if not os.path.exists(targetfolder):
        os.mkdir(targetfolder)
    ofiletsv = os.path.join(targetfolder,"{}.summary.tab".format(mtype))
    with open(ofiletsv,"wt") as fh:
        fh.write("\t".join(["Species","Query Contig","Hit Accession","AlnLen","PercentIDMatch","QStart","QEnd","HStart","HEnd","Evalue","Hit Taxon"])+"\n")
        for f in os.listdir(indir):
            fsplit = f.split(".")
            ext    = ".".join(fsplit[-3:])
            species = ".".join(fsplit[0:-3])
            if ext == targetext:
                with open(os.path.join(indir,f)) as ifh:
                    for line in ifh:
                        fh.write("\t".join([species,line]))
