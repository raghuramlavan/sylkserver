{
  description = "Python OTR implementation; it does not bind to libotr";
  inputs.nixpkgs.url = "nixpkgs/nixos-20.09";
  inputs.python-gnutls-src = {
    url = github:/AGProjects/python-gnutls;
    flake = false;
  };
  inputs.python-otr-src = {
    url = github:python-otr/pure-python-otr;
    flake = false;
  };
  inputs.python-sipsimple-src = {
    url = "github:AGprojects/python-sipsimple";
    flake = false;
  };
  inputs.python-application-src = { url = "github:AGProjects/python3-application?rev=330ccd0693b5b724e4ab964ad6b45d4fcae300a2"; flake = false; };
  inputs.txaio2-src = {
    url = "github:crossbario/txaio?rev=bc28b03efddd678dcea77071ce5ac074a209fefe";
    flake = false;
  };
  inputs.python-sylkserver-src = {
    url = "github:AGProjects/sylkserver?rev=8099169674b20ad00f24d25edb356fa139ea85d1";
    flake = false;
  };

  outputs =
    { self
    , nixpkgs
    , python-gnutls-src
    , python-application-src
    , python-otr-src
    , python-sipsimple-src
    , python-sylkserver-src
    , txaio2-src
    }:
    let


      supportedSystems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);


      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        python-gnutls = with final; python27.pkgs.buildPythonPackage rec {
          pname = "python-gnutls-src";
          version = "3.1.3";

          src = python-gnutls-src;

          buildInputs = [
            gnutls
          ];

          meta = with lib; {
            description = "Python wrapper for the GnuTLS Library";
            homepage = https://github.com/AGProjects/python-gnutls;
            license = licenses.lgpl2Plus;
          };
        };



        python-otr = with final; python27.pkgs.buildPythonPackage rec {
          pname = "python-otr";
          version = "1.0.2";

          src = python-otr-src;

          buildInputs = with  python27Packages; [
            pycrypto
          ];

          doCheck = false;
          /*
          Tests are broken https://github.com/python-otr/pure-python-otr/issues/75
          */
          checkPhase = ''
            ls -l
            SRC_ROOT=$(cd -P $(dirname "$0") && pwd)
            export PYTHONPATH=$PYTHONPATH:"$SRC_ROOT/src"

            nosetests --rednose --verbose
          '';


          meta = with lib; {
            description = "Pure python OTR Implementaion";
            homepage = https://github.com/python-otr/pure-python-otr;
            license = licenses.lgpl2Plus;
          };
        };

        python-application = with final; python27.pkgs.buildPythonPackage rec {
          pname = "python-application";
          version = "2.8.0";

          src = python-application-src;

          buildInputs = with  python27Packages; [
            zope_interface
            twisted
          ];

          meta = with lib; {
            description = "Basic building blocks for python applications";
            homepage = https://github.com/AGProjects/python-application;
            license = licenses.lgpl2Plus;
          };
        };

        txaio2 = with final; python27.pkgs.buildPythonPackage rec {
          pname = "txaio";
          version = "2.8.1";
          src = txaio2-src;
          /*  
             src = python27.pkgs.fetchPypi {
               inherit pname version;
               sha256 = "67e360ac73b12c52058219bb5f8b3ed4105d2636707a36a7cdafb56fe06db7fe";
             };
           */
          checkInputs = with python27Packages; [ pytest mock ];

          propagatedBuildInputs = with python27Packages; [ six twisted ];

          checkPhase = ''
            py.test -k "not test_sdist"
          '';

          # Needs some fixing
          doCheck = false;

          meta = with stdenv.lib; {
            description = "Utilities to support code that runs unmodified on Twisted and asyncio.";
            homepage = "https://github.com/crossbario/txaio";
            license = licenses.mit;
            maintainers = with maintainers; [ nand0p ];
          };
        };


        autobahn2 = with final; python27.pkgs.buildPythonPackage rec {
          pname = "autobahn";
          version = "18.12.1";

          src = python27.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "aebbadb700c13792a2967c79002855d1153b9ec8f2949d169e908388699596ff";
          };

          propagatedBuildInputs = [
            txaio2
            python27Packages.setuptools
            python27Packages.six
            python27Packages.twisted
            python27Packages.zope_interface
            python27Packages.cffi
            python27Packages.trollius
            python27Packages.futures
          ];
          doCheck = false;
          checkInputs = with python27Packages; [ mock pytest zope_interface ];
          checkPhase = ''
            runHook preCheck
            USE_TWISTED=true py.test $out
            runHook postCheck
          '';

          meta = with lib; {
            description = "WebSocket and WAMP in Python for Twisted and asyncio.";
            homepage = "https://crossbar.io/autobahn";
            license = licenses.mit;
            maintainers = with maintainers; [ nand0p ];
          };
        };

        python-sipsimple = with final; python27.pkgs.buildPythonPackage rec {
          pname = "python-sipsimple";
          version = "3.6.0";
          preConfigure = ''
            chmod +x ./deps/pjsip/configure ./deps/pjsip/aconfigure
            export LD=$CC
          '';
          src = python-sipsimple-src;

          nativeBuildInputs = [ pkgs.pkgconfig ];

          buildInputs = with pkgs; [ openssl.dev alsaLib ffmpeg libv4l sqlite libvpx python27Packages.cython ];

          propagatedbuildInputs = [
            autobahn2
            gnutls
            openssl
            python27Packages.dnspython_1
            python27Packages.lxml
            python27Packages.twisted
            python27Packages.dateutil
            python27Packages.greenlet
            python27Packages.xcaplib
            python27Packages.msrplib
            python-gnutls
            python-application
            python-otr
            pkg-config
            python27Packages.setuptools
          ];


          meta = with lib; {
            description = "SIP Simple Client SDK";
            homepage = https://github.com/AGProjects/python-sipsimple;
            license = licenses.lgpl2Plus;
          };
        };


        sylk-server = with final; python27.pkgs.buildPythonApplication rec {
          pname = "sylk-server";
          version = "5.7.0";

          src = python-sylkserver-src;

          propagatedbuildInputs = [
            python27Packages.setuptools
            python-sipsimple
            python-application
            python27Packages.lxml
            python27Packages.twisted
            python27Packages.klein
            autobahn2
            python27Packages.typing
            python27Packages.werkzeug
          ];


          meta = with lib; {
            description = "SIP Simple Client SDK";
            homepage = https://github.com/AGProjects/python-sipsimple;
            license = licenses.lgpl2Plus;
          };
        };
      };


      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) sylk-server;
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.sylk-server);


    };
}
