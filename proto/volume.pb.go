// Code generated by protoc-gen-go. DO NOT EDIT.
// source: volume.proto

package sonm

import proto "github.com/golang/protobuf/proto"
import fmt "fmt"
import math "math"

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// Volume describes volume settings.
type Volume struct {
	// Type describes a volume driver.
	Type string `protobuf:"bytes,1,opt,name=type" json:"type,omitempty"`
	// Options describes a place for your volume settings.
	Options map[string]string `protobuf:"bytes,2,rep,name=options" json:"options,omitempty" protobuf_key:"bytes,1,opt,name=key" protobuf_val:"bytes,2,opt,name=value"`
}

func (m *Volume) Reset()                    { *m = Volume{} }
func (m *Volume) String() string            { return proto.CompactTextString(m) }
func (*Volume) ProtoMessage()               {}
func (*Volume) Descriptor() ([]byte, []int) { return fileDescriptor18, []int{0} }

func (m *Volume) GetType() string {
	if m != nil {
		return m.Type
	}
	return ""
}

func (m *Volume) GetOptions() map[string]string {
	if m != nil {
		return m.Options
	}
	return nil
}

func init() {
	proto.RegisterType((*Volume)(nil), "sonm.Volume")
}

func init() { proto.RegisterFile("volume.proto", fileDescriptor18) }

var fileDescriptor18 = []byte{
	// 177 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xe2, 0xe2, 0x29, 0xcb, 0xcf, 0x29,
	0xcd, 0x4d, 0xd5, 0x2b, 0x28, 0xca, 0x2f, 0xc9, 0x17, 0x62, 0x29, 0xce, 0xcf, 0xcb, 0x55, 0xea,
	0x65, 0xe4, 0x62, 0x0b, 0x03, 0x0b, 0x0b, 0x09, 0x71, 0xb1, 0x94, 0x54, 0x16, 0xa4, 0x4a, 0x30,
	0x2a, 0x30, 0x6a, 0x70, 0x06, 0x81, 0xd9, 0x42, 0xc6, 0x5c, 0xec, 0xf9, 0x05, 0x25, 0x99, 0xf9,
	0x79, 0xc5, 0x12, 0x4c, 0x0a, 0xcc, 0x1a, 0xdc, 0x46, 0x92, 0x7a, 0x20, 0x6d, 0x7a, 0x10, 0x2d,
	0x7a, 0xfe, 0x10, 0x39, 0xd7, 0xbc, 0x92, 0xa2, 0xca, 0x20, 0x98, 0x4a, 0x29, 0x2b, 0x2e, 0x1e,
	0x64, 0x09, 0x21, 0x01, 0x2e, 0xe6, 0xec, 0xd4, 0x4a, 0xa8, 0xb9, 0x20, 0xa6, 0x90, 0x08, 0x17,
	0x6b, 0x59, 0x62, 0x4e, 0x69, 0xaa, 0x04, 0x13, 0x58, 0x0c, 0xc2, 0xb1, 0x62, 0xb2, 0x60, 0x74,
	0x52, 0x89, 0x52, 0x4a, 0xcf, 0x2c, 0xc9, 0x28, 0x4d, 0xd2, 0x4b, 0xce, 0xcf, 0xd5, 0x07, 0xd9,
	0xa5, 0x9b, 0x99, 0xaf, 0x9f, 0x9c, 0x5f, 0x94, 0xaa, 0x0f, 0x76, 0xb6, 0x35, 0x48, 0x28, 0x89,
	0x0d, 0xcc, 0x36, 0x06, 0x04, 0x00, 0x00, 0xff, 0xff, 0xdb, 0x72, 0xae, 0xb2, 0xd2, 0x00, 0x00,
	0x00,
}
