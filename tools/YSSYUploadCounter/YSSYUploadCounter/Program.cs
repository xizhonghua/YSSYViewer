using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Net;

namespace YSSYUploadCounter
{
	class BoardInfo
	{
		public string Name { get; set; }

		public int Count { get; set; }

		public override string ToString ()
		{
			return string.Format ("{0}\t{1}", Name, Count);
		}
	}

	class MainClass
	{
		static readonly List<string> _boardList = new List<string> ();
		static readonly List<BoardInfo> _result = new List<BoardInfo> ();

		private static void LoadBoardList ()
		{
			using (var sr = new StreamReader ("boards.txt")) {
				while (!sr.EndOfStream) {
					var line = sr.ReadLine ();
					if (string.IsNullOrEmpty (line))
						continue;
					_boardList.Add (line);
				}
			}
		}

		private static void SaveBoardInfo ()
		{
			using (var sw = new StreamWriter ("count.txt")) {
				_result.ForEach (sw.WriteLine);
			}
		}

		private static string GetContent (string url)
		{
			var webClient = new WebClient ();
			webClient.Headers [HttpRequestHeader.UserAgent] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36";
			var data = webClient.DownloadData (url);
			var str = System.Text.Encoding.GetEncoding ("GB2312").GetString (data);
			return str;
		}

		private static int GetUploadCount (string board)
		{
			var html = GetContent ("https://bbs.sjtu.edu.cn/bbsfdoc2?board=" + board);

			var regex = new Regex (@"start=(\d+)\>刷新", System.Text.RegularExpressions.RegexOptions.Compiled);

			var match = regex.Match (html);

			if (match.Success) {
				return int.Parse (match.Groups [1].Captures [0].Value);
			}

			return 0;
		}

		public static void Main (string[] args)
		{
			LoadBoardList ();
			Console.WriteLine (_boardList.Count + " boards found!");

			_boardList.ForEach (board => {
				var bi = new BoardInfo { Name = board, Count = GetUploadCount (board) };
				_result.Add (bi);
				Console.WriteLine (bi);
			});

			Console.WriteLine ("Done!");

			SaveBoardInfo ();
		}
	}
}
