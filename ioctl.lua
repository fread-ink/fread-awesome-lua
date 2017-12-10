#!/usr/bin/env luajit

bit = require("bit")
ffi = require("ffi")

ffi.cdef[[

// pulled from linux/mxcfb.h

struct mxcfb_rect {
        uint32_t top;
        uint32_t left;
        uint32_t width;
        uint32_t height;
};

struct mxcfb_alt_buffer_data {
        uint32_t phys_addr;
        uint32_t width;    /* width of entire buffer */
        uint32_t height;   /* height of entire buffer */
        struct mxcfb_rect alt_update_region;    /* region within buffer to update */
};

struct mxcfb_update_data {
        struct mxcfb_rect update_region;
        uint32_t waveform_mode;
        uint32_t update_mode;
        uint32_t update_marker;
        uint32_t hist_bw_waveform_mode;    /*Lab126: Def bw waveform for hist analysis*/
        uint32_t hist_gray_waveform_mode;  /*Lab126: Def gray waveform for hist analysis*/
        int temp;
        unsigned int flags;
        struct mxcfb_alt_buffer_data alt_buffer_data;
};

int ioctl(int __fd, unsigned long int __request, ...);

int fileno(struct FILE* stream);
]]


--local mt = {}
--mxcfb_rect = ffi.metatype("struct mxcfb_rect", {})


mxcfb_rect = ffi.typeof("struct mxcfb_rect")
mxcfb_alt_buffer_data = ffi.typeof("struct mxcfb_alt_buffer_data")
mxcfb_update_data = ffi.typeof("struct mxcfb_update_data")

-- BEGIN arch dependent
local _IOC_NRBITS = 8
local _IOC_TYPEBITS = 8
local _IOC_SIZEBITS = 14
local _IOC_DIRBITS = 2

local _IOC_NONE = 0
local _IOC_WRITE = 1
local _IOC_READ = 2

local _IOC_NRSHIFT = 0
local _IOC_TYPESHIFT = _IOC_NRSHIFT + _IOC_NRBITS
local _IOC_SIZESHIFT = _IOC_TYPESHIFT + _IOC_TYPEBITS
local _IOC_DIRSHIFT = _IOC_SIZESHIFT + _IOC_SIZEBITS
-- END arch dependent

function _IOC_TYPECHECK(t)
  if((ffi.sizeof(t) == ffi.sizeof(t .. '[1]')) and (ffi.sizeof(t) < bit.lshift(1, _IOC_SIZEBITS))) then
    return ffi.sizeof(t)
  else
    error("Invalid size argument for IOC")
  end
end

function _IOC(dir, typen, nr, size)
  if(type(typen) == 'string') then
    typen = string.byte(typen)
  end
  return bit.bor(
    bit.lshift(dir, _IOC_DIRSHIFT),
    bit.lshift(typen, _IOC_TYPESHIFT),
    bit.lshift(nr, _IOC_NRSHIFT),
    bit.lshift(size, _IOC_SIZESHIFT)
  )
end

function _IO(type, nr)
  return _IOC(_IOC_NONE, type, nr, 0)
end

function _IOR(type, nr, size)
  return _IOC(_IOC_READ, type, nr, _IOC_TYPECHECK(size))
end

function _IOW(type, nr, size)
  return _IOC(_IOC_WRITE, type, nr, _IOC_TYPECHECK(size))
end

function _IOWR(type, nr, size)
  return _IOC(bit.bor(_IOC_READ, _IOC_WRITE), type, nr, _IOC_TYPECHECK(size))
end

MXCFB_SEND_UPDATE = _IOW('F', 0x2E, "struct mxcfb_update_data")


function ioctl(fd, request, ...)
--  local args = {...}
  if(type(fd) ~= "number") then
    return ffi.C.ioctl(ffi.C.fileno(fd), request, ...)
  end
  return ffi.C.ioctl(fd, request, ...)
end

fb_dev = io.open("/dev/stderr", "r")


update_data = mxcfb_update_data

ret = ioctl(fb_dev, MXCFB_SEND_UPDATE, update_data)
print(ret)


--local rect = mxcfb_rect(3, 4, 5, 6)
--print(rect.top)