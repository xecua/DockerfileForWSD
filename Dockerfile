FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

WORKDIR /root

ADD ./files/CRF++-0.58.tar.gz ./
ADD ./files/cabocha-0.69.tar.bz2 ./
ADD ./files/font.zip ./

RUN apt update
RUN apt install -y git aria2 curl wget bzip2 sudo make file xz-utils gcc g++ unzip

# install pyenv and anaconda3

RUN git clone https://github.com/yyuu/pyenv.git ~/.pyenv
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
RUN echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
RUN echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
# install Anaconda and setup vim keybind for jupyter
RUN source ~/.bash_profile && pyenv install anaconda3-2019.07 && pyenv global anaconda3-2019.07

# install mecab

RUN apt install -y mecab libmecab-dev mecab-ipadic-utf8 mecab-naist-jdic
RUN git clone https://github.com/neologd/mecab-ipadic-neologd.git
RUN cd mecab-ipadic-neologd/ && ./bin/install-mecab-ipadic-neologd -n -y --ignore_noun_ortho --ignore_noun_sahen_conn_ortho
RUN sed -i.back \
    -e "s:^dicdir = .*$:dicdir = /var/lib/mecab/dic/naist-jdic:" /etc/mecabrc

# install natto

RUN source ~/.bash_profile && pip install natto-py

# install Cabocha

RUN echo 'export PATH="$HOME/usr/bin:$PATH"' >> ~/.bash_profile
RUN echo 'export LD_LIBRARY_PATH=$HOME/usr/lib' >> ~/.bash_profile
RUN mkdir usr

RUN cd ~/CRF++-0.58 && ./configure --prefix=$HOME/usr && make && make install
RUN cd ~/cabocha-0.69 && \
export LDFLAGS="-L$HOME/usr/lib" && \
export CPPFLAGS="-I$HOME/usr/include" && \
./configure --prefix=$HOME/usr --with-mecab-config=`which mecab-config` --with-charset=utf8 && \
make && make install

RUN echo 'source ~/.bash_profile' >> ~/.bashrc

# install editor & tools

RUN apt install -y nano emacs

# setup jupyter notebook
RUN source ~/.bash_profile && jupyter notebook --generate-config \
&& sed -i.back \
    -e "s:^#c.NotebookApp.token = .*$:c.NotebookApp.token = u'':" \
    -e "s:^#c.NotebookApp.ip = .*$:c.NotebookApp.ip = '*':" \
    -e "s:^#c.NotebookApp.open_browser = .*$:c.NotebookApp.open_browser = False:" \
    -e "s:^#c.NotebookApp.notebook_dir = .*$:c.NotebookApp.notebook_dir = '${HOME}/workspace':" \
    ${HOME}/.jupyter/jupyter_notebook_config.py && \
    conda install -c conda-forge jupyter_contrib_nbextensions && \
    mkdir -p $(jupyter --data-dir)/nbextensions && \
    cd $(jupyter --data-dir)/nbextensions && \
    git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding && \
    jupyter nbextension enable vim_binding/vim_binding

RUN unzip font.zip && \
    cp ipaexg00301/ipaexg.ttf /root/.pyenv/versions/anaconda3-2019.07/lib/python3.7/site-packages/matplotlib/mpl-data/fonts/ttf/ && \
    echo "font.family : IPAexGothic" >> /root/.pyenv/versions/anaconda3-2019.07/lib/python3.7/site-packages/matplotlib/mpl-data/matplotlibrc && \
    rm -r ./.cache

RUN ln -s /var/lib/mecab /usr/local/lib/mecab

ENTRYPOINT [ "/bin/bash", "-c" ]
EXPOSE 8888
