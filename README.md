# plass-analysis
Benchmark for PLASS paper

# Prochlorococcus
The following tools have to be installed in order to create and execute the prochlorococcus benchmark/
    
    mmseqs2
    prodigal
    bbmap

After installing the tools execute the following commands to setup the benchmarking data:

    :::bash
    git clone https://github.com/martin-steinegger/plass-analysis
    cd plass-analysis/Prochloroccus
    chmod u+x *
    makeProchlorococcus.sh
    
Each tool can be executed separately by calling the respective shell scripts e.g. runPlassProchloroccus.sh, runMetaspadesProchloroccus.sh, ...
However the assembler binary has to be in the $PATH variable.
