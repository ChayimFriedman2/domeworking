use std::io::{Read, Write};
use std::net;
use std::time::Duration;

use dome_cloomnik::{register_modules, Context, HookResult, WrenHandle, WrenVM};
use once_cell::unsync::OnceCell;

#[no_mangle]
#[allow(non_snake_case)]
extern "C" fn PLUGIN_onInit(get_api: *mut libc::c_void, ctx: *mut libc::c_void) -> libc::c_int {
    unsafe {
        dome_cloomnik::init_plugin(
            get_api,
            ctx,
            dome_cloomnik::Hooks {
                on_init: Some(on_init),
                pre_update: None,
                post_update: None,
                pre_draw: None,
                post_draw: None,
                on_shutdown: None,
            },
        )
    }
}

thread_local! {
    static TCP_STREAM_HANDLE: OnceCell<WrenHandle> = OnceCell::new();
}
/// # SAFETY
///
/// Call this function only from a foreign, after the "domeworking" module has been loaded.
unsafe fn set_slot_tcp_stream(vm: &mut WrenVM, slot: usize, stream: TcpStream) {
    TCP_STREAM_HANDLE.with(|handle| {
        let handle = handle.get_or_init(|| {
            vm.get_variable("domeworking", "TcpStream", slot);
            vm.get_slot_handle(slot)
        });
        vm.set_slot_handle(slot, handle);
        vm.set_slot_new_foreign_unchecked(slot, slot, stream);
    });
}

struct TcpListener(Option<net::TcpListener>);

impl TcpListener {
    const CLOSED_MSG: &'static str = "TCP listener closed.";

    fn bind(vm: &WrenVM) -> Self {
        let addr = vm.get_slot_string(1).expect("Invalid address.");
        Self(Some(
            net::TcpListener::bind(addr).expect("Failed to bind TCP listener."),
        ))
    }

    fn accept(&mut self, vm: &mut WrenVM) {
        let (stream, _) = self
            .0
            .as_ref()
            .expect(Self::CLOSED_MSG)
            .accept()
            .expect("Failed to accept.");
        // SAFETY: We are inside a foreign.
        unsafe {
            set_slot_tcp_stream(vm, 0, TcpStream(Some(stream)));
        }
    }

    fn close(&mut self, _vm: &mut WrenVM) {
        self.0.take().expect(Self::CLOSED_MSG);
    }
}

struct TcpStream(Option<net::TcpStream>);

impl TcpStream {
    const CLOSED_MSG: &'static str = "TCP stream closed.";

    fn connect(vm: &WrenVM) -> Self {
        let addr = vm.get_slot_string(1).expect("Invalid address.");
        Self(Some(
            net::TcpStream::connect(addr).expect("Failed to connect TCP stream."),
        ))
    }

    fn stream(&self) -> &net::TcpStream {
        self.0.as_ref().expect(Self::CLOSED_MSG)
    }

    fn remote_addr(&mut self, vm: &mut WrenVM) {
        vm.set_slot_string(
            0,
            &self
                .stream()
                .peer_addr()
                .expect("Failed to retrieve remote address.")
                .to_string(),
        );
    }

    fn read(&mut self, vm: &mut WrenVM) {
        let mut buf = [0; 65_535];
        let read_len = self.stream().read(&mut buf).expect("Failed to read.");
        if read_len == 0 {
            self.0.take();
            vm.set_slot_null(0);
            return;
        }
        vm.set_slot_bytes(0, &buf[..read_len]);
    }

    fn read_timeout(&mut self, vm: &mut WrenVM) {
        const FAILED_MSG: &str = "Failed to read.";
        let timeout = vm.get_slot_double(1);
        let timeout = Duration::from_secs_f64(timeout);
        self.stream()
            .set_read_timeout(Some(timeout))
            .expect(FAILED_MSG);
        let mut buf = [0; 65_535];
        match self.stream().read(&mut buf) {
            Ok(0) => {
                // Stream closed
                self.0.take();
                vm.set_slot_null(0);
            }
            Err(_) => vm.set_slot_null(0), // Timed out
            Ok(read_len) => vm.set_slot_bytes(0, &buf[..read_len]),
        };
        self.stream().set_read_timeout(None).expect(FAILED_MSG);
    }

    fn write(&mut self, vm: &mut WrenVM) {
        let buf = vm.get_slot_bytes(1);
        self.stream().write_all(&buf).expect("Failed to write.");
    }

    fn closed(&mut self, vm: &mut WrenVM) {
        vm.set_slot_bool(0, self.0.is_none())
    }

    fn close(&mut self, _vm: &mut WrenVM) {
        self.0.take().expect(Self::CLOSED_MSG);
    }
}

fn on_init(mut ctx: Context) -> HookResult {
    (register_modules! {
        ctx,
        module "domeworking" {
            foreign class TcpStream = connect of TcpStream {
                "construct connect(addr) {}"
                foreign remoteAddr = remote_addr
                foreign read() = read
                foreign read(timeout) = read_timeout
                foreign write(data) = write
                // Isn't accurate
                foreign closed = closed
                foreign close() = close
            }
            foreign class TcpListener = bind of TcpListener {
                "construct bind(addr) {}"
                foreign accept() = accept
                foreign close() = close
            }
        }
    })?;

    Ok(())
}
