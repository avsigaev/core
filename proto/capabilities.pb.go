// Code generated by protoc-gen-go. DO NOT EDIT.
// source: capabilities.proto

/*
Package sonm is a generated protocol buffer package.

It is generated from these files:
	capabilities.proto
	hub.proto
	insonmnia.proto
	miner.proto

It has these top-level messages:
	Capabilities
	CPUDevice
	RAMDevice
	GPUDevice
	ListRequest
	ListReply
	HubInfoRequest
	TaskRequirements
	HubStartTaskRequest
	HubStartTaskReply
	HubStatusMapRequest
	HubStatusRequest
	HubStatusReply
	PingRequest
	PingReply
	CPUUsage
	MemoryUsage
	NetworkUsage
	ResourceUsage
	InfoReply
	StopTaskRequest
	StopTaskReply
	TaskStatusRequest
	TaskStatusReply
	StatusMapReply
	ContainerRestartPolicy
	TaskLogsRequest
	TaskLogsChunk
	TaskResourceRequirements
	MinerInfoRequest
	MinerHandshakeRequest
	MinerHandshakeReply
	MinerStartRequest
	MinerStartReply
	MinerStatusMapRequest
*/
package sonm

import proto "github.com/golang/protobuf/proto"
import fmt "fmt"
import math "math"

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.ProtoPackageIsVersion2 // please upgrade the proto package

type Capabilities struct {
	Cpu []*CPUDevice `protobuf:"bytes,1,rep,name=cpu" json:"cpu,omitempty"`
	Mem *RAMDevice   `protobuf:"bytes,2,opt,name=mem" json:"mem,omitempty"`
	Gpu []*GPUDevice `protobuf:"bytes,3,rep,name=gpu" json:"gpu,omitempty"`
}

func (m *Capabilities) Reset()                    { *m = Capabilities{} }
func (m *Capabilities) String() string            { return proto.CompactTextString(m) }
func (*Capabilities) ProtoMessage()               {}
func (*Capabilities) Descriptor() ([]byte, []int) { return fileDescriptor0, []int{0} }

func (m *Capabilities) GetCpu() []*CPUDevice {
	if m != nil {
		return m.Cpu
	}
	return nil
}

func (m *Capabilities) GetMem() *RAMDevice {
	if m != nil {
		return m.Mem
	}
	return nil
}

func (m *Capabilities) GetGpu() []*GPUDevice {
	if m != nil {
		return m.Gpu
	}
	return nil
}

type CPUDevice struct {
	Name   string            `protobuf:"bytes,1,opt,name=name" json:"name,omitempty"`
	Vendor string            `protobuf:"bytes,2,opt,name=vendor" json:"vendor,omitempty"`
	Cores  int32             `protobuf:"varint,3,opt,name=cores" json:"cores,omitempty"`
	Mhz    float64           `protobuf:"fixed64,4,opt,name=mhz" json:"mhz,omitempty"`
	Ext    map[string]string `protobuf:"bytes,5,rep,name=ext" json:"ext,omitempty" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
}

func (m *CPUDevice) Reset()                    { *m = CPUDevice{} }
func (m *CPUDevice) String() string            { return proto.CompactTextString(m) }
func (*CPUDevice) ProtoMessage()               {}
func (*CPUDevice) Descriptor() ([]byte, []int) { return fileDescriptor0, []int{1} }

func (m *CPUDevice) GetName() string {
	if m != nil {
		return m.Name
	}
	return ""
}

func (m *CPUDevice) GetVendor() string {
	if m != nil {
		return m.Vendor
	}
	return ""
}

func (m *CPUDevice) GetCores() int32 {
	if m != nil {
		return m.Cores
	}
	return 0
}

func (m *CPUDevice) GetMhz() float64 {
	if m != nil {
		return m.Mhz
	}
	return 0
}

func (m *CPUDevice) GetExt() map[string]string {
	if m != nil {
		return m.Ext
	}
	return nil
}

type RAMDevice struct {
	Total uint64 `protobuf:"varint,1,opt,name=total" json:"total,omitempty"`
	Used  uint64 `protobuf:"varint,2,opt,name=used" json:"used,omitempty"`
}

func (m *RAMDevice) Reset()                    { *m = RAMDevice{} }
func (m *RAMDevice) String() string            { return proto.CompactTextString(m) }
func (*RAMDevice) ProtoMessage()               {}
func (*RAMDevice) Descriptor() ([]byte, []int) { return fileDescriptor0, []int{2} }

func (m *RAMDevice) GetTotal() uint64 {
	if m != nil {
		return m.Total
	}
	return 0
}

func (m *RAMDevice) GetUsed() uint64 {
	if m != nil {
		return m.Used
	}
	return 0
}

type GPUDevice struct {
	Name   string            `protobuf:"bytes,1,opt,name=name" json:"name,omitempty"`
	Vendor string            `protobuf:"bytes,2,opt,name=vendor" json:"vendor,omitempty"`
	Ext    map[string]string `protobuf:"bytes,3,rep,name=ext" json:"ext,omitempty" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
}

func (m *GPUDevice) Reset()                    { *m = GPUDevice{} }
func (m *GPUDevice) String() string            { return proto.CompactTextString(m) }
func (*GPUDevice) ProtoMessage()               {}
func (*GPUDevice) Descriptor() ([]byte, []int) { return fileDescriptor0, []int{3} }

func (m *GPUDevice) GetName() string {
	if m != nil {
		return m.Name
	}
	return ""
}

func (m *GPUDevice) GetVendor() string {
	if m != nil {
		return m.Vendor
	}
	return ""
}

func (m *GPUDevice) GetExt() map[string]string {
	if m != nil {
		return m.Ext
	}
	return nil
}

func init() {
	proto.RegisterType((*Capabilities)(nil), "sonm.Capabilities")
	proto.RegisterType((*CPUDevice)(nil), "sonm.CPUDevice")
	proto.RegisterType((*RAMDevice)(nil), "sonm.RAMDevice")
	proto.RegisterType((*GPUDevice)(nil), "sonm.GPUDevice")
}

func init() { proto.RegisterFile("capabilities.proto", fileDescriptor0) }

var fileDescriptor0 = []byte{
	// 298 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xac, 0x92, 0xc1, 0x4a, 0xf3, 0x40,
	0x14, 0x85, 0x99, 0x4e, 0x5a, 0xfe, 0xdc, 0x5f, 0x50, 0x06, 0x91, 0xc1, 0x55, 0xcc, 0x2a, 0xb8,
	0xc8, 0x42, 0x51, 0xc4, 0x9d, 0xd4, 0x92, 0x95, 0x20, 0x03, 0x3e, 0x40, 0x9a, 0x5e, 0x6a, 0x30,
	0x93, 0x09, 0xc9, 0x24, 0xb6, 0xbe, 0x8a, 0x8f, 0xe3, 0x8b, 0xc9, 0x9d, 0xa4, 0x6d, 0x70, 0x29,
	0xee, 0xce, 0xc9, 0x9c, 0x7b, 0xee, 0xfd, 0x20, 0x20, 0xb2, 0xb4, 0x4a, 0x97, 0x79, 0x91, 0xdb,
	0x1c, 0x9b, 0xb8, 0xaa, 0x8d, 0x35, 0xc2, 0x6b, 0x4c, 0xa9, 0xc3, 0x77, 0x38, 0x9a, 0x8f, 0xde,
	0xc4, 0x05, 0xf0, 0xac, 0x6a, 0x25, 0x0b, 0x78, 0xf4, 0xff, 0xea, 0x38, 0xa6, 0x4c, 0x3c, 0x7f,
	0x7e, 0x79, 0xc4, 0x2e, 0xcf, 0x50, 0xd1, 0x1b, 0x45, 0x34, 0x6a, 0x39, 0x09, 0xd8, 0x21, 0xa2,
	0x1e, 0x9e, 0x76, 0x11, 0x8d, 0x9a, 0x22, 0xeb, 0xaa, 0x95, 0x7c, 0xdc, 0x92, 0x1c, 0x5a, 0xd6,
	0x55, 0x1b, 0x7e, 0x31, 0xf0, 0xf7, 0xc5, 0x42, 0x80, 0x57, 0xa6, 0x1a, 0x25, 0x0b, 0x58, 0xe4,
	0x2b, 0xa7, 0xc5, 0x19, 0xcc, 0x3a, 0x2c, 0x57, 0xa6, 0x76, 0xab, 0x7c, 0x35, 0x38, 0x71, 0x0a,
	0xd3, 0xcc, 0xd4, 0xd8, 0x48, 0x1e, 0xb0, 0x68, 0xaa, 0x7a, 0x23, 0x4e, 0x80, 0xeb, 0xd7, 0x0f,
	0xe9, 0x05, 0x2c, 0x62, 0x8a, 0xa4, 0xb8, 0x04, 0x8e, 0x1b, 0x2b, 0xa7, 0xee, 0x08, 0xf9, 0x03,
	0x25, 0x5e, 0x6c, 0xec, 0xa2, 0xb4, 0xf5, 0x56, 0x51, 0xe8, 0xfc, 0x16, 0xfe, 0xed, 0x3e, 0x50,
	0xd3, 0x1b, 0x6e, 0x87, 0x53, 0x48, 0xd2, 0xc6, 0x2e, 0x2d, 0x5a, 0x1c, 0x0e, 0xe9, 0xcd, 0xfd,
	0xe4, 0x8e, 0x85, 0x37, 0xe0, 0xef, 0xd1, 0x29, 0x66, 0x8d, 0x4d, 0x0b, 0x37, 0xea, 0xa9, 0xde,
	0x10, 0x5a, 0xdb, 0xe0, 0xca, 0xcd, 0x7a, 0xca, 0xe9, 0xf0, 0x93, 0x81, 0x9f, 0xfc, 0x0a, 0x7e,
	0x80, 0xe2, 0x63, 0xa8, 0xe4, 0x6f, 0xa1, 0x96, 0x33, 0xf7, 0x83, 0x5c, 0x7f, 0x07, 0x00, 0x00,
	0xff, 0xff, 0x95, 0xca, 0xa8, 0xdd, 0x36, 0x02, 0x00, 0x00,
}
