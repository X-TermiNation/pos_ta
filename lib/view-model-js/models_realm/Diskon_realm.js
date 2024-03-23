const BarangSchema = {
  name: 'Barang',
  embedded: true,
  properties: {
    _id: 'objectId',
    Qty: 'int',
    exp_date: 'date',
    harga_barang: 'int',
    id_reference: 'string',
    jenis_barang: 'string',
    kategori_barang: 'string',
    nama_barang: 'string',
  },
};
  
  const DiskonSchema = {
    name: 'Diskon',
    properties: {
      _id: 'objectId',
      Barang: 'Barang[]',
      __v: 'int?',
      end_date: 'date',
      nama_diskon: 'string',
      persentase_diskon: 'int',
      start_date: 'date',
    },
    primaryKey: '_id',
  };
  
  module.exports = { BarangSchema, DiskonSchema };