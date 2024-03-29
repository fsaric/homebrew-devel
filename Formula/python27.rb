class Python27 < Formula
  desc "Interpreted, interactive, object-oriented programming language"
  homepage "https://www.python.org/"
  url "https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz"
  sha256 "b62c0e7937551d0cc02b8fd5cb0f544f9405bafc9a54d3808ed4594812edef43"

  bottle do
    root_url "https://github.com/fsaric/homebrew-devel/releases/download/python27-2.7.18"
    sha256 catalina:     "c8e9440fba59a14621b9c956577ca756898bc8d355401af2d589ea9189d6f4a8"
    sha256 x86_64_linux: "091966d059d24a6775311d47bcbb2de7508931fd9384b304036f9a2841f993df"
  end

  depends_on "pkg-config" => :build
  depends_on "gdbm"
  depends_on "openssl@1.1"
  depends_on "readline"
  depends_on "sqlite"

  uses_from_macos "bzip2"
  uses_from_macos "expat"
  uses_from_macos "libffi"
  uses_from_macos "ncurses"
  uses_from_macos "unzip"
  uses_from_macos "zlib"

  def install
    args = %w[
      --enable-ipv6
      --with-ensurepip
    ]
    cflags   = []
    ldflags  = []
    cppflags = []

    if MacOS.sdk_path_if_needed
      # Help Python's build system (setuptools/pip) to build things on SDK-based systems
      # The setup.py looks at "-isysroot" to get the sysroot (and not at --sysroot)
      cflags  << "-isysroot #{MacOS.sdk_path}" << "-I#{MacOS.sdk_path}/usr/include"
      ldflags << "-isysroot #{MacOS.sdk_path}"
      # For the Xlib.h, Python needs this header dir with the system Tk
      # Yep, this needs the absolute path where zlib needed a path relative
      # to the SDK.
      cflags  << "-I#{MacOS.sdk_path}/System/Library/Frameworks/Tk.framework/Versions/8.5/Headers"

      # We want our readline and openssl! This is just to outsmart the detection code,
      # superenv handles that cc finds includes/libs!
      inreplace "setup.py" do |s|
        s.gsub! "do_readline = self.compiler.find_library_file(lib_dirs, 'readline')",
                "do_readline = '#{Formula["readline"].opt_lib}/libhistory.dylib'"
        s.gsub! "/usr/local/ssl", Formula["openssl@1.1"].opt_prefix
      end

      inreplace "setup.py" do |s|
        s.gsub! "sqlite_setup_debug = False", "sqlite_setup_debug = True"
        s.gsub! "for d_ in inc_dirs + sqlite_inc_paths:",
                "for d_ in ['#{Formula["sqlite"].opt_include}']:"

        # Allow sqlite3 module to load extensions:
        # https://docs.python.org/library/sqlite3.html#f1
        s.gsub! 'sqlite_defines.append(("SQLITE_OMIT_LOAD_EXTENSION", "1"))', ""
      end

      args << "CFLAGS=#{cflags.join(" ")}" unless cflags.empty?
      args << "LDFLAGS=#{ldflags.join(" ")}" unless ldflags.empty?
      args << "CPPFLAGS=#{cppflags.join(" ")}" unless cppflags.empty?
    end
    system "./configure", *std_configure_args, *args
    system "make", "install"

    rm bin/"2to3"
  end

  test do
    system "true"
  end
end
