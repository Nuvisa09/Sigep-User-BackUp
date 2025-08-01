import 'dart:typed_data';
import 'package:demandium/utils/app_constants.dart';
import 'package:get/get.dart';
import 'package:demandium/helper/date_converter.dart';
import 'package:demandium/feature/booking/controller/booking_details_controller.dart';
import 'package:demandium/feature/booking/model/booking_details_model.dart';
import 'package:demandium/feature/booking/model/invoice.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:demandium/utils/dimensions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;


class InvoiceController {
   static Future<Uint8List> generateUint8List(
       BookingDetailsContent bookingDetailsContent,
       List<InvoiceItem> items,
       BookingDetailsController controller) async{
     final pdf = Document();
     ImageProvider? imageProvider;

     try {
       imageProvider = await downloadImage(Get.find<SplashController>().configModel.content!.logoFullPath ?? "");
     }catch (e){
       if (kDebugMode) {
         print(e.toString());
       }
     }


     var invoice = Invoice(
       provider: Provider(
       name: bookingDetailsContent.provider != null? bookingDetailsContent.provider!.companyName! :'',
       address: bookingDetailsContent.provider != null? bookingDetailsContent.provider!.companyAddress!: '',
       phone: bookingDetailsContent.provider != null? bookingDetailsContent.provider!.companyPhone!: '',
      ),
      serviceman: ServicemanInvoice(
        name: bookingDetailsContent.serviceman != null? "${bookingDetailsContent.serviceman!.user!.firstName!} ${bookingDetailsContent.serviceman!.user!.lastName!}":'',
        phone: bookingDetailsContent.serviceman != null? bookingDetailsContent.serviceman!.user!.phone!: '',
      ),
      info: InvoiceInfo(
        date: bookingDetailsContent.serviceSchedule,
        description: 'Status Pembayaran : ',
        number: bookingDetailsContent.readableId.toString(),
        paymentStatus: bookingDetailsContent.partialPayments != null && bookingDetailsContent.partialPayments!.isNotEmpty && bookingDetailsContent.isPaid == 0 ? "Bayar Sebagian" : bookingDetailsContent.isPaid == 0 ?"Belum Dibayar": 'Lunas',
      ),
      items: items,
    );



    pdf.addPage(MultiPage(
      build: (context) => [
        buildInvoiceImage(imageProvider,bookingDetailsContent,invoice),
        SizedBox(height: 0.6 * PdfPageFormat.cm),
        invoiceIDSchedule(invoice.info.number,invoice.info.date),
        buildHeader(invoice,bookingDetailsContent),
        SizedBox(height: 0.8 * PdfPageFormat.cm),
        buildInvoice(invoice),
        SizedBox(height:Dimensions.paddingSizeDefault),
        buildTotal(bookingDetailsContent,controller,invoice.info.paymentStatus),
      ],
      footer: (context) => buildFooter(bookingDetailsContent),
    ));

    return pdf.save();
  }

  static Widget invoiceIDSchedule(String invoiceID, String? invoiceSchedule) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("Bukti Pembayaran # $invoiceID",style: pw.TextStyle(fontWeight: FontWeight.bold)),
      Text("Jadwal Layanan : ${DateConverter.dateMonthYearTimeTwentyFourFormat(DateTime.tryParse(invoiceSchedule ??"")!)}"),
    ]
  );

  static Widget buildHeader(Invoice invoice,BookingDetailsContent content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          serviceAddress(
            name: "${content.customer?.firstName ?? ""} ${content.customer?.lastName ?? ""}",
            address: content.serviceAddress!.address?.replaceAll("null","") ?? "",
            email: content.customer?.email??"",
            phone: content.customer?.phone ?? "",
          ),
          Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
            SizedBox(height: Dimensions.paddingSizeSmall),
            buildProviderSection(invoice.provider,invoice.serviceman),
          ])
        ],
      ),
    ],
  );

  static Widget serviceAddress({
    required String name,
    required String email,
    required String phone,
    required String address}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Alamat Layanan", style: TextStyle(fontWeight: FontWeight.bold)),
        buildSimpleText(title: 'Nama Pelanggan', value: name),
        if(email!='')
        buildSimpleText(title: 'Email', value: email),
        if(phone!='')
        buildSimpleText(title: 'Handphone', value: phone),
        if(address != '' )
          SizedBox(
              width: Get.width*.4,
            child: Text('Alamat: $address')
          )
    ]
  );

  static Widget buildProviderSection(Provider provider,ServicemanInvoice serviceman) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if(serviceman.name != '' && serviceman.phone != '')
        Text("Detail Penyedia Jasa", style: TextStyle(fontWeight: FontWeight.bold)),
      Text(serviceman.name),
      // Text(provider.address),
      Text(serviceman.phone),
      SizedBox(height: Dimensions.paddingSizeDefault),
      if(provider.name != '' && provider.phone != '')
        Text("Detail Mitra", style: TextStyle(fontWeight: FontWeight.bold)),
      Text(provider.name),
      // Text(provider.address),
      Text(provider.phone),
    ],
  );
  static Widget buildServiceManSection(Serviceman serviceman) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [

    ],
  );

  static Widget buildInvoiceInfo(InvoiceInfo info) {
    final titles = <String>[
      'Nomor Pembayaran:',
      'Tanggal Pembayaran:',
      'Status Pembayaran:',
    ];

    final data = <String?>[
      info.number,
      info.date,
      info.paymentStatus,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(titles.length, (index) {
        final title = titles[index];
        final value = data[index];
        return buildText(title: title, value: value, width: 200);
      }),
    );
  }



  static Widget buildSupplierAddress(Supplier supplier) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 1 * PdfPageFormat.mm),
      Text(supplier.address),
    ],
  );

  static Widget buildTitle(Invoice invoice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bukti Pembayaran',
        style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
      //Text(invoice.info.description),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
    ],
  );

  static Widget buildInvoice(Invoice invoice) {
    final headers = [
      'Deskripsi',
      'Harga Satuan',
      'Jumlah',
      'Diskon',
      'Pajak',
      'Total',
    ];
    final data = invoice.items.map((item) {
      return [
        item.serviceName,
        item.unitPrice,
        item.quantity,
        item.discountAmount,
        item.tax,
        item.unitAllTotal,
      ];
    }).toList();

    return ClipRRect(
      horizontalRadius: Dimensions.paddingSizeExtraSmall,
      verticalRadius: Dimensions.paddingSizeExtraSmall,
      child:  Container(
          color:  PdfColors.grey300,
          child: TableHelper.fromTextArray(
            headers: headers,

            data: data,
            columnWidths: {
              0: (kIsWeb) ? FixedColumnWidth(Get.width / 12) : FixedColumnWidth(Get.width / 4),
            },
            border: null,
            headerStyle: TextStyle(fontWeight: FontWeight.bold,),
            headerDecoration: const BoxDecoration(color: PdfColors.grey400),
            cellHeight: 30,
            cellAlignments: {
              0: Alignment.centerLeft,
              1: Alignment.center,
              2: Alignment.center,
              3: Alignment.center,
              4: Alignment.center,
              5: Alignment.center,
              6: Alignment.centerRight,
            },
          )
      ),
    );

  }

  static Widget buildTotal(
      BookingDetailsContent bookingDetailsContent,
      BookingDetailsController controller,
      String paymentStatus) {
    double serviceDiscount = 0;
    bookingDetailsContent.bookingDetails?.forEach((service) {
      serviceDiscount = serviceDiscount + service.discountAmount!;
    });

    double paidAmount = 0;

    double totalBookingAmount = bookingDetailsContent.totalBookingAmount ?? 0;
    bool isPartialPayment = bookingDetailsContent.partialPayments !=null && bookingDetailsContent.partialPayments!.isNotEmpty;

    if(isPartialPayment) {
      bookingDetailsContent.partialPayments?.forEach((element) {
        paidAmount = paidAmount + (element.paidAmount ?? 0);
      });
    }else{
      paidAmount  = totalBookingAmount - (bookingDetailsContent.additionalCharge ?? 0);
    }
    double dueAmount = totalBookingAmount - paidAmount;
    //double additionalCharge = isPartialPayment ? totalBookingAmount - paidAmount : bookingDetailsContent.additionalCharge ?? 0;

    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status Pembayaran",style: pw.TextStyle(fontWeight: FontWeight.bold)),
              Text(paymentStatus),
            ]
          ),
          Spacer(flex: 3),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // buildText(
                //   title: 'Sub Total(VAT excluded)',
                //   value: controller.allTotalCost.toString(),
                //   unite: true,
                // ),

                buildText(
                  title: 'Diskon Layanan',
                  value: '(-) ${serviceDiscount.toString()}',
                  unite: true,
                ),
                buildText(
                  title: 'Diskon voucher',
                  value: '(-) ${bookingDetailsContent.totalCouponDiscountAmount.toString()}',
                  unite: true,
                ),
                buildText(
                  title: 'Diskon Promo Spesial',
                  value: '(-) ${bookingDetailsContent.totalCampaignDiscountAmount.toString()}',
                  unite: true,
                ),
                if(bookingDetailsContent.totalReferralDiscountAmount != null && bookingDetailsContent.totalReferralDiscountAmount! > 0)
                buildText(
                  title: 'Diskon Referral',
                  value: '(-) ${bookingDetailsContent.totalReferralDiscountAmount.toString()}',
                  unite: true,
                ),

                if(bookingDetailsContent.extraFee != null && bookingDetailsContent.extraFee! > 0)
                  buildText(
                    title: Get.find<SplashController>().configModel.content?.additionalChargeLabelName ??"",
                    value: "(+) ${bookingDetailsContent.extraFee?.toStringAsFixed(2)}",
                    unite: true,
                  ),

                buildText(
                  title: 'Pajak',
                  value: "(+) ${bookingDetailsContent.totalTaxAmount!.toStringAsFixed(2)}",
                  unite: true,
                ),

                Divider(),
                bookingDetailsContent.partialPayments != null && bookingDetailsContent.partialPayments!.isNotEmpty ?
                Column(children: [
                  buildText(
                    title: 'Total Keseluruhan',
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    value: double.tryParse(controller.bookingDetailsContent!.totalBookingAmount.toString())!.toStringAsFixed(2),
                    unite: true,
                  ),
                  ListView.builder(itemBuilder: (context, index){

                    String paidWith = bookingDetailsContent.partialPayments?[index].paidWith ?? "";

                    return buildText(
                        title: '${paidWith == "digital" && bookingDetailsContent.paymentMethod == "offline_payment" ? ""  : (paidWith == "wallet" || paidWith == "digital")  ? "Pembayaran Via '"  : ""}'
                            '${ paidWith == "digital" && bookingDetailsContent.paymentMethod =="offline_payment" ? "Offline Payment" : paidWith == "digital" ? bookingDetailsContent.paymentMethod :  paidWith =="wallet" ? "wallet" : "Bayar Setelah Selesai" }',
                        value: bookingDetailsContent.partialPayments?[index].paidAmount.toString() ?? "0"
                    );
                  },
                    itemCount: bookingDetailsContent.partialPayments!.length,
                  ),
                  bookingDetailsContent.partialPayments?.length == 1 &&  dueAmount > 0?
                  buildText(
                      title: "Bayar Tunai Nanti (Setelah Layanan)", value: "$dueAmount"
                  )  : SizedBox(),



                  if(bookingDetailsContent.additionalCharge !=0 && bookingDetailsContent.paymentMethod != "Bayar Setelah Layanan")
                    buildText(
                      title:  bookingDetailsContent.additionalCharge != null
                          && bookingDetailsContent.additionalCharge! > 0 ? (bookingDetailsContent.bookingStatus == "pending" || bookingDetailsContent.bookingStatus == "accepted" || bookingDetailsContent.bookingStatus == "ongoing") ?'Jumlah Tagihan (Bayar Tunai setelah layanan)' : "Jumlah Dibayar (Bayar Tunai setelah layanan) "  : "Jumlah Pengembalian",
                      titleStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                      value: (bookingDetailsContent.additionalCharge ?? 0).toStringAsFixed(2),
                      unite: true,
                    ),

                ]):
                Column(children: [
                  buildText(
                    title: 'Jumlah Keseluruhan',
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    value: controller.bookingDetailsContent!.totalBookingAmount!.toStringAsFixed(2),
                    unite: true,
                  ),
                  if(bookingDetailsContent.additionalCharge != null && bookingDetailsContent.additionalCharge! > 0 && bookingDetailsContent.paymentMethod != "cash_after_service")
                    Column(children: [
                      buildText(
                        title: 'Jumlah Dibayar (${bookingDetailsContent.paymentMethod =="offline_payment"? "Offline" : bookingDetailsContent.paymentMethod =="wallet_payment" ? "Wallet" : bookingDetailsContent.paymentMethod =="cash_after_service" ? "Cash After Service" : bookingDetailsContent.paymentMethod})',
                        titleStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        value: ((bookingDetailsContent.totalBookingAmount ?? 0) -(bookingDetailsContent.additionalCharge ?? 0)).toStringAsFixed(2),
                        unite: true,
                      ),
                      bookingDetailsContent.additionalCharge! > 0 ?
                      buildText(
                        title:   (bookingDetailsContent.bookingStatus == "pending" || bookingDetailsContent.bookingStatus == "accepted" || bookingDetailsContent.bookingStatus == "ongoing") ?'Jumlah Tagihan (Bayar Tunai setelah layanan))' : "Jumlah Dibayar (Bayar Tunai setelah layanan)",
                        titleStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        value: (bookingDetailsContent.additionalCharge ?? 0).toStringAsFixed(2),
                        unite: true,
                      ): SizedBox(),

                    ])
                ]),
                SizedBox(height: 2 * PdfPageFormat.mm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(BookingDetailsContent bookingDetailsContent) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text("Jika Anda butuh bantuan atau ingin memberi masukan tentang situs ini, silakan hubungi kami melalui telepon atau email.",textAlign: TextAlign.center),
      SizedBox(height: Dimensions.paddingSizeSmall),

      Container(
        color: PdfColors.grey100,
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(Get.find<SplashController>().configModel.content?.businessPhone ?? ""),
                SizedBox(width: 20),
                Text(Get.find<SplashController>().configModel.content?.businessEmail ?? ""),
              ]
            ),
            SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(AppConstants.baseUrl),
            SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(Get.find<SplashController>().configModel.content?.footerText ?? "",
             textAlign: TextAlign.center
           ),
          ]
        )
      ),
    ],
  );

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        SizedBox(width: Get.width*.4,child: Text(value)),
      ],
    );
  }

  static buildText({
    required String title,
     String? value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: unite ? style : null)),
          Text(value ??"", style: unite ? style : null),
        ],
      ),
    );
  }

   static Widget buildInvoiceImage(ImageProvider? netImage,BookingDetailsContent bookingDetailsContent,Invoice invoice) {
     return Container(
       width: Dimensions.invoiceImageWidth,
       height: Dimensions.invoiceImageHeight,
       child: netImage != null ? pw.Image(netImage) : SizedBox(),);
   }

   static Future<ImageProvider> downloadImage(String imageUrl) async {
    http.Response response = await http.get(
        Uri.parse(imageUrl)
     );
     return MemoryImage(response.bodyBytes);
   }
}
