class Thrift < Formula
  desc "Framework for scalable cross-language services development"
  homepage "https://thrift.apache.org/"

  stable do
    url "https://www.apache.org/dyn/closer.cgi?path=/thrift/0.10.0/thrift-0.10.0.tar.gz"
    sha256 "2289d02de6e8db04cbbabb921aeb62bfe3098c4c83f36eec6c31194301efa10b"

    # Apply any necessary patches (none currently required)
    [
      # Example patch:
      #
      # Apply THRIFT-2201 fix from master to 0.9.1 branch (required for clang to compile with C++11 support)
      # %w{836d95f9f00be73c6936d407977796181d1a506c f8e14cbae1810ade4eab49d91e351459b055c81dba144c1ca3c5d6f4fe440925},
    ].each do |name, sha|
      patch do
        url "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=commitdiff_plain;h=#{name}"
        sha256 sha
      end
    end
  end

  bottle do
    cellar :any
    rebuild 1
  end

  head do
    url "https://git-wip-us.apache.org/repos/asf/thrift.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "pkg-config" => :build
  end

  option "with-haskell", "Install Haskell binding"
  option "with-erlang", "Install Erlang binding"
  option "with-java", "Install Java binding"
  option "with-perl", "Install Perl binding"
  option "with-php", "Install PHP binding"
  option "with-libevent", "Install nonblocking server libraries"

  depends_on "bison" => :build
  depends_on "boost"
  depends_on "openssl"
  depends_on "libevent" => :optional
  depends_on :python => :optional

  def install
    system "./bootstrap.sh" unless build.stable?

    exclusions = ["--without-ruby", "--disable-tests", "--without-php_extension"]

    exclusions << "--without-python" if build.without? "python"
    exclusions << "--without-haskell" if build.without? "haskell"
    exclusions << "--without-java" if build.without? "java"
    exclusions << "--without-perl" if build.without? "perl"
    exclusions << "--without-php" if build.without? "php"
    exclusions << "--without-erlang" if build.without? "erlang"

    ENV.cxx11 if MacOS.version >= :mavericks && ENV.compiler == :clang

    # Don't install extensions to /usr:
    ENV["PY_PREFIX"] = prefix
    ENV["PHP_PREFIX"] = prefix

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--libdir=#{lib}",
                          "--with-openssl=#{Formula["openssl"].opt_prefix}",
                          *exclusions
    ENV.deparallelize
    system "make"
    system "make", "install"
  end

  def caveats; <<-EOS.undent
    To install Ruby binding:
      gem install thrift

    To install PHP extension for e.g. PHP 5.5:
      brew install homebrew/php/php55-thrift
  EOS
  end
end
